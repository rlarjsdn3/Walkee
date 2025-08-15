//
//  AlanSSEClient.swift
//  Health
//
//  Created by Seohyun Kim on 8/12/25.
//

/// Alan API 실시간 스트리밍 응답을 위한 경량 SSE(Server-Sent Events) 클라이언트입니다.
///
/// `AlanSSEClient`는 Alan API `/api/v1/question/sse-streaming` 엔드포인트에 연결하여
/// AI 응답을 실시간(`AlanStreamingResponse`)으로 받아옵니다.
/// 이를 통해 LLM 챗봇처럼 글자가 한 글자씩, 또는 토큰 단위로 표시되는
/// 인터랙션을 구현할 수 있습니다.
///
/// ## 개요
/// - HTTP 기반 SSE(Server-Sent Events) 프로토콜 지원
/// - `data:` 라인의 JSON 데이터를 `AlanStreamingResponse`로 자동 파싱/디코딩
/// - `.continue` 이벤트와 `.complete` 이벤트 처리
/// - `.complete` 이벤트 수신 시 스트림 자동 종료
///
/// ## 사용 예시
/// ```swift
/// let client = AlanSSEClient()
/// let stream = client.connect(url: url)
///
/// Task {
///     do {
///         for try await event in stream {
///             print("수신한 데이터:", event.data.content)
///         }
///     } catch {
///         print("SSE 오류:", error)
///     }
/// }
/// ```
///
/// - Note: 필요 시 `disconnect()`를 호출하여 수동으로 스트림을 종료할 수 있습니다.
import Foundation
import os

private enum SSEParseError: Error { case emptyData, badJSON }

enum AlanSSEClientError: Error, LocalizedError {
	case badHTTPStatus(Int)
	case badContentType(String)
	
	var errorDescription: String? {
		switch self {
		case .badHTTPStatus(let code):   return "SSE HTTP 상태코드 오류: \(code)"
		case .badContentType(let ct):    return "SSE Content-Type이 올바르지 않음: \(ct)"
		}
	}
}

private let log = Logger(subsystem: "Health", category: "SSE")

final class AlanSSEClient: NSObject {
	private var session: URLSession?
	private var task: URLSessionDataTask?

	typealias Stream = AsyncThrowingStream<AlanStreamingResponse, Error>
	private var continuation: Stream.Continuation?

	private var byteBuffer = Data()
	private let newline2 = Data("\n\n".utf8)
	
	private lazy var decoder = JSONDecoder() // 재사용

	func connect(url: URL) -> Stream {
		let stream = Stream { continuation in
			self.continuation = continuation
		}

		let cfg = URLSessionConfiguration.default
		cfg.httpAdditionalHeaders = [
			"Accept": "text/event-stream",
			"Cache-Control": "no-cache",
			// 보수적으로 "identity"를 강제하면 전송 최적화가 막힐 수 있어 주석하고 테스트 시도
			"Accept-Encoding": "identity"
		]
		
		cfg.timeoutIntervalForRequest = 600            // 10분
		cfg.timeoutIntervalForResource = 0             // 무제한
		cfg.waitsForConnectivity = true                // 네트워크 복구 시 자동 재시도
		cfg.allowsConstrainedNetworkAccess = true
		cfg.allowsExpensiveNetworkAccess = true
		
		session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)

		var req = URLRequest(url: url)
		req.httpMethod = "GET"
		req.timeoutInterval = 0
		req.setValue("text/event-stream", forHTTPHeaderField: "Accept")

		Log.net.info("SSE connect -> \(url.absoluteString, privacy: .public)")
		if let headers = cfg.httpAdditionalHeaders {
			Log.net.debug("headers: \(String(describing: headers), privacy: .public)")
		}

		task = session?.dataTask(with: req)
		task?.resume()
		return stream
	}

	func disconnect() {
		Log.net.info("SSE disconnect()")
		continuation?.finish()
		continuation = nil
		task?.cancel()
		session?.invalidateAndCancel()
		session = nil
		byteBuffer.removeAll(keepingCapacity: false)
	}
	
	private func decodeEvent(_ json: String) throws -> AlanStreamingResponse {
		if let data = json.data(using: .utf8) {
			if let dto = try? decoder.decode(AlanStreamingResponse.self, from: data) { return dto }
		}
		// '{'type':'...'..}' 패턴이면 한 번만 보정
		if json.contains("'}") || json.contains("':") {
			let fixed = json
				.replacingOccurrences(of: #"'([A-Za-z0-9_]+)'\s*:"#,
									  with: #""$1":"#,
									  options: .regularExpression)
				.replacingOccurrences(of: #":\s*'([^']*)'"#,
									  with: #": "$1""#,
									  options: .regularExpression)
			if let data = fixed.data(using: .utf8),
			   let dto  = try? decoder.decode(AlanStreamingResponse.self, from: data) {
				return dto
			}
		}
		throw NSError(domain: "SSE", code: -10, userInfo: [NSLocalizedDescriptionKey:"decode fail"])
	}
	/// 서버가 싱글쿼트로 보내는 payload에서 type/speak/content만 안전 추출
	private func fallbackParsePseudoJSON(_ s: String) -> AlanStreamingResponse? {
		func match(_ pattern: String) -> String? {
			let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
			guard let m = regex.firstMatch(in: s, options: [], range: NSRange(location: 0, length: (s as NSString).length)),
				  m.numberOfRanges >= 2 else { return nil }
			return (s as NSString).substring(with: m.range(at: 1))
		}

		guard let typeStr = match(#"type':\s*'([^']+)'"#) else { return nil }
		
		// content와 speak 둘 다 시도
		let rawContent = match(#"content':\s*'(.*)'\s*}\s*}"#)
		let rawSpeak   = match(#"speak':\s*'(.*)'\s*}\s*}"#)

		// 치환: \n -> 실제 개행
		func normalize(_ t: String?) -> String? {
			t?.replacingOccurrences(of: #"\\n"#, with: "\n")
		}

		let type = AlanStreamingResponse.StreamingType(rawValue: typeStr) ?? .continue
		let dto  = AlanStreamingResponse(
			type: type,
			data: .init(content: normalize(rawContent) ?? normalize(rawSpeak),
						speak: normalize(rawSpeak))
		)
		//Log.sse.info("fallback parsed type=\(type.rawValue, privacy: .public) len=\((dto.data.content ?? "").count, privacy: .public)")
		return dto
	}
	
	private func coerceSingleQuotedJSON(_ raw: String) -> String {
		// 1) 키:   '{'type': 'continue', 'data': {...}}'  의 'type', 'data' -> "type", "data"
		var fixed = raw.replacingOccurrences(
			of: #"'([A-Za-z0-9_]+)'\s*:"#,
			with: #""$1":"#,
			options: .regularExpression
		)
		// 2) 값:   ": '...'"  -> ": "..."    (문장 안의 U+2018/2019(‘ ’)는 건드리지 않음)
		fixed = fixed.replacingOccurrences(
			of: #":\s*'([^']*)'"#,
			with: #": "$1""#,
			options: .regularExpression
		)
		return fixed
	}

	/// 한 개의 SSE data 블록 문자열을 AlanStreamingResponse로 파싱
	private func decodeSSEJSON(_ jsonString: String) throws -> AlanStreamingResponse {
		guard jsonString.isEmpty == false else { throw SSEParseError.emptyData }

		// 0) 원본 미리보기 로그
		let preview = jsonString.prefix(120)
		log.debug("block json preview=\(String(preview), privacy: .public)")

		// 1) 그대로 디코드 시도
		if let data = jsonString.data(using: .utf8) {
			do {
				let dto = try JSONDecoder().decode(AlanStreamingResponse.self, from: data)
				return dto
			} catch {
				print(error)
				//log.debug("direct decode failed: \(String(describing: error), privacy: .public)")
			}
		}

		// 2) 싱글쿼트 -> 유효 JSON으로 보정 후 재시도
		let fixed = coerceSingleQuotedJSON(jsonString)
		let fixedPreview = fixed.prefix(120)
		//log.debug("fixed json preview=\(String(fixedPreview), privacy: .public)")

		guard let fixedData = fixed.data(using: .utf8) else { throw SSEParseError.badJSON }
		do {
			let dto = try JSONDecoder().decode(AlanStreamingResponse.self, from: fixedData)
			return dto
		} catch {
			log.error("decode failed even after fix: \(String(describing: error), privacy: .public)")
			throw error
		}
	}
}

extension AlanSSEClient: URLSessionDataDelegate {

	//HTTP 상태/헤더 확인
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
					didReceive response: URLResponse,
					completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		
		if let http = response as? HTTPURLResponse {
			let status = http.statusCode
			let contentType = (http.allHeaderFields["Content-Type"] as? String) ?? ""
			
			Log.net.info("HTTP status = \(http.statusCode, privacy: .public)")
			Log.net.info("Content-Type = \(contentType, privacy: .public)")
			
			if status != 200 {
				continuation?.finish(throwing: AlanSSEClientError.badHTTPStatus(http.statusCode))
				task?.cancel()
				completionHandler(.cancel)
				return
			}
			if contentType.contains("text/event-stream") == false {
				continuation?.finish(throwing: AlanSSEClientError.badContentType(contentType))
				task?.cancel()
				completionHandler(.cancel)
				return
			}
		}
		completionHandler(.allow)
	}

	//청크 수신 -> 버퍼 누적 -> 완성 블록 파싱
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		byteBuffer.append(data)
		
		// 2) 이벤트 경계 찾기: LF×2, CRLF×2 모두 지원 (가장 앞 경계부터 처리)
		while true {
			// \n\n
			let lf2   = Data([0x0A, 0x0A])
			// \r\n\r\n 맨앞줄로 리턴되게 \r 단순 개행 \n
			let crlf2 = Data([0x0D, 0x0A, 0x0D, 0x0A])
			
			let r1 = byteBuffer.range(of: lf2)
			let r2 = byteBuffer.range(of: crlf2)
			
			// 두 후보 중 더 앞에 있는 경계를 채택
			let cutRange: Range<Data.Index>?
			if let a = r1, let b = r2 { cutRange = (a.lowerBound < b.lowerBound) ? a : b }
			else { cutRange = r1 ?? r2 }
			
			guard let sep = cutRange else { break } // 경계 더 없음 → 다음 수신까지 대기
			
			// 3) 경계 앞까지를 한 블록으로 파싱
			let blockData = byteBuffer.subdata(in: 0..<sep.lowerBound)
			byteBuffer.removeSubrange(0..<sep.upperBound) // 경계 포함 제거
			
			guard let block = String(data: blockData, encoding: .utf8)
					?? String(data: blockData, encoding: .ascii) else { continue }
			
#if DEBUG
//			print("SSE block raw:\n\(block)")
#endif
			// 4) SSE 필드 파싱 (comment/heartbeat 무시)
			// 여러 줄 중 "data:" 라인만 모음 (여러 줄 data 지원)
			let lines = block.split(separator: "\n", omittingEmptySubsequences: false)
			var datas: [String] = []
			for line in lines {
				if line.first == ":" { continue }                 // : ping - ... (heartbeat)
				if line.hasPrefix("event:") { /* 필요하면 사용 */ }
				if let p = line.range(of: "data:") {
					let v = line[p.upperBound...].trimmingCharacters(in: .whitespaces)
					datas.append(String(v))
				}
			}
			guard datas.isEmpty == false else { continue }
			
			let json = datas.joined(separator: "\n")
			do {
				let dto = try decodeEvent(json)
				continuation?.yield(dto)
				if dto.type == .complete { continuation?.finish() }
			} catch {
				// 필요시 샘플링 로그
				Log.net.error("decodeEvent error: \(error)")
			}
		}
	}

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		//		if let error {
		//			Log.net.error("didCompleteWithError: \(String(describing: error), privacy: .public)")
		//			continuation?.finish(throwing: error)
		//		} else {
		//			Log.net.info("server closed without error")
		//		}
		//		disconnect()
		if error == nil, byteBuffer.isEmpty == false {
			if let tail = String(data: byteBuffer, encoding: .utf8)
				?? String(data: byteBuffer, encoding: .ascii) {
				let lines = tail.split(separator: "\n", omittingEmptySubsequences: false)
				let datas = lines.compactMap { line -> String? in
					guard let p = line.range(of: "data:") else { return nil }
					return String(line[p.upperBound...]).trimmingCharacters(in: .whitespaces)
				}
				if datas.isEmpty == false {
					let json = datas.joined(separator: "\n")
					if let dto = try? decodeEvent(json) {
						continuation?.yield(dto)
					}
				}
			}
		}
		
		if let error { continuation?.finish(throwing: error) }
		else { continuation?.finish() }
		
		//disconnect()
	}
}
