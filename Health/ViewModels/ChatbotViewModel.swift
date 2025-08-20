//
//  ChatbotViewModel.swift
//  Health
//
//  Created by Seohyun Kim on 8/19/25.
//

import Foundation

/// 챗봇 기능 전용 Alan SSE 스트리밍 전용, 챗봇 프롬프트 관리 ViewModel.
/// - NOTE: 일반 질의/리셋은 AlanViewModel이 담당.
/// - NOTE: 서비스/클라이언트는 프로토콜에 의존해 테스트/모킹이 쉬움.
@MainActor
final class ChatbotViewModel {
	@Injected private var sseService: AlanSSEServiceProtocol
	@Injected private var networkService: NetworkService
	
	var onActionText: ((String) -> Void)?
	var onStreamChunk: ((String) -> Void)?
	var onStreamCompleted: (() -> Void)?
	var onError: ((String) -> Void)?
	
	private var streamTask: Task<Void, Never>?
	private var clientID: String { AppConfiguration.clientID }
	
	deinit { streamTask?.cancel() }
	
	// 단순 스트리밍
	func startStreamingQuestion(_ content: String, autoReset: Bool = true) {
		streamTask?.cancel()
		streamTask = Task { [weak self] in
			guard let self else { return }
			await self._startStreaming(content: content, canRetry: autoReset)
		}
	}
	
	/// 서버 500 등 복구 가능 오류 시 1회 reset 후 재시도
	func startStreamingQuestionWithAutoReset(_ content: String) {
		streamTask?.cancel()
		
		let masked = PrivacyService.maskSensitiveInfo(in: content)
		
		print("=== 마스킹 디버그 ===")
		print("[Chatbot] Original: \(content)")
		print("[Chatbot] Masked  : \(masked)")
		print("==================")
		
		Log.privacy.info("Original: \(content, privacy: .public)")
		Log.privacy.info("Masked  : \(masked, privacy: .public)")
#if DEBUG
		startMockStreaming(content)
#else
		streamTask = Task { [weak self] in
			guard let self else { return }
			await self._startStreaming(content: content, canRetry: true)
		}
#endif
	}
	
	private func _startStreaming(content: String, canRetry: Bool) async {
		var callComplete = true
		defer { if callComplete { onStreamCompleted?() } }
		
		do {
			let stream = try sseService.stream(content: content)
			streamLoop: for try await event in stream {
				switch event.type {
				case .action:
					if let s = event.data.speak ?? event.data.content, !s.isEmpty { onActionText?(s) }
				case .continue:
					if let c = event.data.content, !c.isEmpty { onStreamChunk?(c) }
				case .complete:
					break streamLoop
				}
			}
		} catch {
			if canRetry, isRecoverable(error) {
				callComplete = false
				onActionText?("세션 초기화 후 재시도…")
				await resetAgentState()
				try? await Task.sleep(nanoseconds: 300_000_000)
				await _startStreaming(content: content, canRetry: false)
				return
			}
			onError?(error.localizedDescription)
		}
	}
	
	
	private func isRecoverable(_ error: Error) -> Bool {
		if let e = error as? AlanSSEClientError {
			switch e {
			case .badHTTPStatus(let code):
				return code == 500
			case .badContentType:
				return true
			}
		}
		return false
	}
	
	private func resetAgentState() async {
		let ep = APIEndpoint.resetState(clientID: clientID)
		do { _ = try await networkService.request(endpoint: ep, as: AlanResetStateResponse.self) }
		catch { onError?("세션 초기화 실패: \(error.localizedDescription)") }
	}
	
	
	// MARK: - DEBUG Mock Streaming
	private func startMockStreaming(_ content: String) {
		streamTask = Task { [weak self] in
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
				
				if !mock.action.speak.isEmpty {
					self.onActionText?(mock.action.speak)
				}
				
				for ch in mock.content {
					try await Task.sleep(nanoseconds: 30_000_000) // 30ms
					self.onStreamChunk?(String(ch))
				}
			} catch {
				self.onError?(error.localizedDescription)
			}
		}
	}
}
