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
private let log = Logger(subsystem: "Health", category: "SSE")

final class AlanSSEClient: NSObject {
	private var session: URLSession?
	private var task: URLSessionDataTask?

	typealias Stream = AsyncThrowingStream<AlanStreamingResponse, Error>
	private var continuation: Stream.Continuation?

	private var buffer = ""

	func connect(url: URL) -> Stream {
		let stream = Stream { continuation in
			self.continuation = continuation
		}

		let cfg = URLSessionConfiguration.default
		cfg.httpAdditionalHeaders = [
			"Accept": "text/event-stream",
			"Accept-Encoding": "identity"
		]
		session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)

		var req = URLRequest(url: url)
		req.httpMethod = "GET"

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
		buffer.removeAll(keepingCapacity: false)
	}
	
	private func decodeEvent(from jsonString: String) throws -> AlanStreamingResponse {
		guard jsonString.isEmpty == false else {
			throw NSError(domain: "SSE", code: -1) // 빈 블록
		}
		
		// 1) 엄격 JSON 먼저
		if let d = jsonString.data(using: .utf8) {
			do { return try JSONDecoder().decode(AlanStreamingResponse.self, from: d) }
			catch { /* fallthrough to fixed */ }
		}
		
		// 2) 싱글쿼트 -> 유효 JSON으로 보정
		let fixed = coerceSingleQuotedJSON(jsonString)
		guard let data = fixed.data(using: .utf8) else {
			throw NSError(domain: "SSE", code: -2) // 인코딩 실패
		}
		return try JSONDecoder().decode(AlanStreamingResponse.self, from: data)
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
			Log.net.info("HTTP status = \(http.statusCode, privacy: .public)")
			let contentType = (http.allHeaderFields["Content-Type"] as? String) ?? ""
			Log.net.info("Content-Type = \(contentType, privacy: .public)")

			if http.statusCode != 200 {
				Log.net.error("Non-200 status, SSE may fail")
			}
			if contentType.contains("text/event-stream") == false {
				Log.net.error("Content-Type is NOT text/event-stream")
			}
		}
		completionHandler(.allow)
	}

	//청크 수신 -> 버퍼 누적 -> 완성 블록 파싱
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		guard let chunk = String(data: data, encoding: .utf8) else {
			Log.sse.error("chunk decode failed (bytes=\(data.count, privacy: .public))")
			return
		}
		//Log.sse.debug("chunk bytes=\(data.count, privacy: .public) preview=\(String(chunk.prefix(120)), privacy: .public)")

		buffer += chunk.replacingOccurrences(of: "\r\n", with: "\n")

		while let range = buffer.range(of: "\n\n") {
			let rawBlock = String(buffer[..<range.lowerBound])
			buffer = String(buffer[range.upperBound...])

			//Log.sse.debug("---- block ----\n\(rawBlock, privacy: .public)")

			// 여러 줄 data: 라인만 모아 합침
			let lines = rawBlock.split(separator: "\n", omittingEmptySubsequences: false)
			let dataLines = lines.compactMap { line -> String? in
				if let r = line.range(of: "data:") {
					return String(line[r.upperBound...]).trimmingCharacters(in: .whitespaces)
				} else { return nil }
			}
			guard dataLines.isEmpty == false else {
				//Log.sse.debug("block has no data: (heartbeat/comment)")
				continue
			}

			let jsonString = dataLines.joined(separator: "\n")
			//Log.sse.debug("jsonString.len=\(jsonString.count, privacy: .public)")

			guard let jsonData = jsonString.data(using: .utf8) else {
				//Log.sse.error("jsonString to Data failed")
				continue
			}

			do {
				let dto = try decodeEvent(from: jsonString)
					continuation?.yield(dto)
					if dto.type == .complete { continuation?.finish() }

			} catch {
				print(error)
				//Log.sse.error("decode error: \(String(describing: error), privacy: .public)")
			}
		}
	}

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let error {
			Log.net.error("didCompleteWithError: \(String(describing: error), privacy: .public)")
			continuation?.finish(throwing: error)
		} else {
			Log.net.info("server closed without error")
		}
		disconnect()
	}
}
