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
		case .badContentType(let contentType):    return "SSE Content-Type이 올바르지 않음: \(contentType)"
		}
	}
}

private let log = Logger(subsystem: "Health", category: "SSE")

final class AlanSSEClient: NSObject, AlanSSEClientProtocol {
	typealias Stream = AsyncThrowingStream<AlanStreamingResponse, Error>
	
	private var session: URLSession?
	private var task: URLSessionDataTask?
	private var continuation: Stream.Continuation?

	private var byteBuffer = Data()
	private lazy var decoder = JSONDecoder() // 재사용

	func connect(url: URL) -> Stream {
		let stream = Stream { continuation in
			self.continuation = continuation
			continuation.onTermination = { [weak self] _ in
				self?.disconnect()
			}
		}
		
		startSession(with: url)
		
		return stream
	}
	
	private func startSession(with url: URL) {
		let configuration = URLSessionConfiguration.default
		configuration.httpAdditionalHeaders = [
			"Accept": "text/event-stream",
			"Cache-Control": "no-cache",
			"Accept-Encoding": "identity"
		]
		configuration.timeoutIntervalForRequest  = 600   // 10분
		configuration.timeoutIntervalForResource = 0     // 무제한
		configuration.waitsForConnectivity = true
		configuration.allowsConstrainedNetworkAccess = true
		configuration.allowsExpensiveNetworkAccess  = true
		
		session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
		
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.timeoutInterval = 0
		request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
		
		//Log.net.info("SSE connect -> \(url.absoluteString, privacy: .public)")
		task = session?.dataTask(with: request)
		task?.resume()
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
	
	deinit {
		task?.cancel()
		session?.invalidateAndCancel()
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
				let dto = try AlanSSEParser.decodeEvent(json)
				continuation?.yield(dto)
				if dto.type == .complete { continuation?.finish() }
			} catch {
				// 필요시 샘플링 로그
				Log.net.error("decodeEvent error: \(error)")
			}
		}
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
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
					if let dto = try? AlanSSEParser.decodeEvent(json) {
						continuation?.yield(dto)
					}
				}
			}
		}
		
		if let error {
			continuation?.finish(throwing: error)
		} else {
			continuation?.finish()
		}
	}
}
