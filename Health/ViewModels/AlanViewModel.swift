import Foundation

@MainActor
final class AlanViewModel {
	
	@Injected private var networkService: NetworkService

	private(set) var errorMessage: String?
	
	private var clientID: String {
		AppConfiguration.clientID
	}
	
	var didReceiveResponseText: ((String) -> Void)?
	//  MARK: 스트리밍용 콜백 (조각, 완료, 에러)
	var onStreamChunk: ((String) -> Void)?
	var onStreamCompleted: (() -> Void)?
	var onActionText: ((String) -> Void)?
	private var sseClient: AlanSSEClient?
	
	// MARK: - 일반 질문 형식 APIEndpoint
	func sendQuestion(_ content: String) async -> String? {
		let endpoint = APIEndpoint.ask(content: content, clientID: clientID)
		
		do {
			let response = try await networkService.request(endpoint: endpoint, as: AlanQuestionResponse.self)
			didReceiveResponseText?(response.content)
			errorMessage = nil
			return response.content
		} catch {
			errorMessage = error.localizedDescription
			return nil
		}
	}
	
	// MARK: SSE Streaming 형식의 응답을 받는 질문 요청
	func startStreamingQuestion(_ content: String) {
#if DEBUG
		// ── Debug: 로컬 목 JSON을 “한 글자씩” 흘려서 SSE처럼 보이게
		Task { @MainActor [weak self] in
			guard let self else { return }
			defer { self.onStreamCompleted?() }
			
			struct Mock: Decodable {
				struct Action: Decodable { let name: String; let speak: String }
				let action: Action
				let content: String
			}
			
			do {
				guard let url = Bundle.main.url(forResource: "mock_ask_response", withExtension: "json") else {
					self.onActionText?("모킹 파일을 찾을 수 없어요.")
					return
				}
				let data = try Data(contentsOf: url)
				let mock = try JSONDecoder().decode(Mock.self, from: data)
				
				if mock.action.speak.isEmpty == false {
					self.onActionText?(mock.action.speak)
				}
				
				// 실제 SSE 느낌: 20~40ms 간격으로 한 글자씩
				for ch in mock.content {
					try await Task.sleep(nanoseconds: 30_000_000)
					self.onStreamChunk?(String(ch))
				}
			} catch {
				self.errorMessage = error.localizedDescription
			}
		}
		#else
		// ── Release: 실제 SSE
		do {
			let safe = PrivacyService.maskSensitiveInfo(in: content)
			let url = try buildStreamingURL(content: safe, clientID: clientID)
			let client = AlanSSEClient()
			self.sseClient = client
			
			let stream = client.connect(url: url)
			Task { @MainActor [weak self]  in
				guard let self else { return }
				defer {
					self.sseClient?.disconnect()
					self.sseClient = nil
					self.onStreamCompleted?()
				}
				
				do {
					streamLoop: for try await event in stream {
						switch event.type {
						case .action:
							if let speak = event.data.speak ?? event.data.content, !speak.isEmpty {
								self.onActionText?(speak)
							}
						case .continue:
							if let piece = event.data.content, !piece.isEmpty {
								self.onStreamChunk?(piece)
							}
						case .complete:
							break streamLoop
						}
					}
				} catch {
					self.errorMessage = error.localizedDescription
				}
			}
		} catch {
			self.errorMessage = error.localizedDescription
			self.onStreamCompleted?()
		}
		#endif
	}
	
	func resetAgentState() async {
		let endpoint = APIEndpoint.resetState(clientID: clientID)
		
		do {
			_ = try await networkService.request(endpoint: endpoint, as: AlanResetStateResponse.self)
			errorMessage = nil
		} catch {
			errorMessage = error.localizedDescription
		}
	}
	
	// MARK: - SSE 요청 중 Server Error 500 이 뜰 때 reset State
	func startStreamingQuestionWithAutoReset(_ content: String) {
#if DEBUG
		// Debug 모드에서는 mock 데이터 사용
		startStreamingQuestion(content)
#else
		// Release 모드에서는 실제 SSE + 자동 재시도 로직
		Task { @MainActor [weak self] in
			guard let self else { return }
			await self._startStreaming(content: content, canRetry: true)
		}
#endif
	}

	private func _startStreaming(content: String, canRetry: Bool) async {
		var shouldCallCompleted = true
		do {
			let safe = PrivacyService.maskSensitiveInfo(in: content)
			let url = try buildStreamingURL(content: safe, clientID: clientID)
			let client = AlanSSEClient()
			self.sseClient = client
			
			let stream = client.connect(url: url)
			defer {
				self.sseClient?.disconnect()
				self.sseClient = nil
				if shouldCallCompleted {
					self.onStreamCompleted?()
				}
			}
			
			streamLoop: for try await event in stream {
				switch event.type {
				case .action:
					if let speak = event.data.speak ?? event.data.content, !speak.isEmpty {
						self.onActionText?(speak)
					}
				case .continue:
					if let piece = event.data.content, !piece.isEmpty {
						self.onStreamChunk?(piece)
					}
				case .complete:
					break streamLoop
				}
			}
		} catch {
			// 복구 가능한 경우: reset 후 1회 재시도
			let recoverable: Bool = {
				if let e = error as? AlanSSEClientError {
					switch e {
					case .badHTTPStatus(let code): return code == 500
					case .badContentType: return true
					}
				}
				return false
			}()
			
			if recoverable, canRetry {
				// 진행 멘트(옵션)
				shouldCallCompleted = false
				self.onActionText?("세션을 초기화하고 다시 시도 중…")
				await self.resetAgentState() // DELETE /api/v1/reset-state (문서 확인)
				try? await Task.sleep(nanoseconds: 300_000_000)
				await self._startStreaming(content: content, canRetry: false)
				return
			}
			
			self.errorMessage = error.localizedDescription
			//self.onStreamCompleted?()
		}
	}
}

extension AlanViewModel {
	func buildStreamingURL(content: String, clientID: String) throws -> URL {
		let endpoint = APIEndpoint.askStreaming(content: content, clientID: clientID)
		var comps = URLComponents(url: endpoint.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
		comps?.queryItems = endpoint.queryItems
		guard let url = comps?.url else { throw NetworkError.badURL }
		return url
	}
}
