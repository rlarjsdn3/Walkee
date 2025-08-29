//
//  AlanSSEService.swift
//  Health
//
//  Created by Seohyun Kim on 8/19/25.
//

import Foundation

final class AlanSSEService: AlanSSEServiceProtocol {

	private let client: AlanSSEClientProtocol
	
	init(client: AlanSSEClientProtocol) {
		self.client = client
	}
	// NOTE: clientID는 resetState 호출에 의해 변경될 수 있으므로, 항상 최신 상태로 반영하기 위해 계산 프로퍼티로 유지
	// server 에러와 사용자의 요청값 history reset해 응답값 정확성 높이기 위함
	private var clientID: String { AppConfiguration.clientID }
	
	/// Alan SSE 스트리밍 응답을 비동기 에러 가능한 스트림으로 제공합니다.
	/// - Parameter content: 사용자 메시지
	/// - Returns: `AsyncThrowingStream<AlanStreamingResponse, Error>`
	
	func stream(content: String) throws -> AsyncThrowingStream<AlanStreamingResponse, any Error> {
		let masked = PrivacyService.maskSensitiveInfo(in: content)
		let url = try buildStreamingURL(content: masked)
		let rawStream = client.connect(url: url)
		
		return AsyncThrowingStream { continuation in
			Task {
				do {
					streamLoop: for try await event in rawStream {
						continuation.yield(event)
						if event.type == .complete { break streamLoop }
					}
					continuation.finish()
				} catch {
					continuation.finish(throwing: error)
				}
			}
		}
	}
	
	private func buildStreamingURL(content: String) throws -> URL {
		let endpoint = APIEndpoint.askStreaming(content: content, clientID: clientID)
		var comps = URLComponents(
			url: endpoint.baseURL.appendingPathComponent(endpoint.path),
			resolvingAgainstBaseURL: false
		)
		comps?.queryItems = endpoint.queryItems
		
#if !DEBUG
		if let url = comps?.url?.absoluteString {
			//Log.net.info("[AlanSSE][RELEASE] 요청 URL: \(url, privacy: .public)")
		}
#endif
		
		guard let url = comps?.url else { throw NetworkError.badURL }
		return url
	}
}
