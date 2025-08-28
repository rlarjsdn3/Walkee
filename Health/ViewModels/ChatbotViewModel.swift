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
	@Injected private var promptBuilderService: PromptBuilderService
	
	var onActionText: ((String) -> Void)?
	var onStreamChunk: ((String) -> Void)?
	var onFinalRender: ((NSAttributedString) -> Void)? // 변경: 인덱스 추가
	var onStreamCompleted: ((String) -> Void)?
	var onError: ((String) -> Void)?
	
	private var streamTask: Task<Void, Never>?
	private var didResetInThisCycle = false
	private var clientID: String { AppConfiguration.clientID }
	
	private var streamingBuffer: String = "" // 변경: 스트리밍 버퍼 추가
	
	// 중복 reset 방지용
	private var lastResetAt: ContinuousClock.Instant?
	private var resetInFlight = false
	
	deinit { streamTask?.cancel() }
	
	
	/// 자동 리셋처리 되면서 비식별화와 걷기 프롬프트 설계로 Streaming 요청에 응답
	/// - Parameter rawMessage: 원문 사용자 요청값 메시지
	func startPromptChatWithAutoReset(_ rawMessage: String) {
		streamTask?.cancel()
		streamingBuffer = ""
		didResetInThisCycle = false
		
		streamTask = Task { [weak self] in
			guard let self else { return }
			
			let masked = PrivacyService.maskSensitiveInfo(in: rawMessage)
			print("=== 마스킹 디버그 ===")
			print("[Chatbot] Original: \(rawMessage)")
			print("[Chatbot] Masked  : \(masked)")
			print("==================")
#if DEBUG
			let isUnitTest = NSClassFromString("XCTestCase") != nil
			if !isUnitTest {
				startMockStreaming(masked)
				return
			}
#endif
			do {
				let prompt = try await promptBuilderService.makePrompt(
					message: masked, context: nil, option: .chat
				)
				await self._startStreaming(content: prompt, canRetry: true)
			} catch {
				onError?("프롬프트 생성 실패: \(error.localizedDescription)")
			}
		}
	}
	
	// MARK: - 상황별 reset agent
	
	/// 채팅 화면 종료시 안전하게 호출할 리셋 메서드
	func resetSessionOnExit() {
		streamTask?.cancel() // 열려있던 SSE 즉시 취소
		Log.chat.info("view exit detected > cancel SSE & call reset-state")
		Task { [weak self] in
			guard let self else { return }
//			await resetAgentState() // 내부에서 Alan reset-state 호출
			await self.resetAgentState(throttle: .milliseconds(800))
		}
	}
	
	/// 서버/화면 종료 등에서 호출되는 리셋
	/// - Parameter throttle: 지정하면 최근 reset 시각으로부터 주어진 시간 내 호출은 스킵
	private func resetAgentState(throttle: Duration?) async {
		// 1) 근접 호출 스킵
		if let t = throttle, let last = lastResetAt, last + t > .now {
			Log.chat.info("skip reset (throttled)")
			return
		}
		// 2) 동시호출 스킵
		if resetInFlight { return }
		resetInFlight = true
		defer { resetInFlight = false }

		// 3) 의존성 캡처(테스트/DI 안전)
		let svc = networkService
		let ep = APIEndpoint.resetState(clientID: clientID)

		do {
			_ = try await svc.request(endpoint: ep, as: AlanResetStateResponse.self)
			lastResetAt = .now
			Log.chat.info("reset-state success for clientID=\(self.clientID, privacy: .public)")
		} catch {
			Log.chat.error("reset-state failed: \(error.localizedDescription, privacy: .public)")
			onError?("세션 초기화 실패: \(error.localizedDescription)")
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
		defer { if callComplete { onStreamCompleted?("") } }
		
		do {
			let stream = try sseService.stream(content: content)
			streamLoop: for try await event in stream {
				switch event.type {
				case .action:
					if let s = event.data.speak ?? event.data.content, !s.isEmpty { onActionText?(s) }
				case .continue:
					if let c = event.data.content, !c.isEmpty { onStreamChunk?(c) }
				case .complete:
					let tail = event.data.content ?? ""
					streamingBuffer.append(tail)
					
					// 마크다운 렌더 → 한 번만 표시
					let attributed = ChatMarkdownRenderer.renderFinalMarkdown(streamingBuffer)
					onFinalRender?(attributed)
					
					// plain 최종도 한 번
					onStreamCompleted?(streamingBuffer)
					
					streamingBuffer = ""
					callComplete = false
					break streamLoop
				}
			}
		} catch {
			callComplete = false
			// 기존 세션 초기화 로직 유지
			if canRetry, isRecoverable(error) {
				callComplete = false
				onActionText?("세션 초기화 후 재시도…")
				
				if !didResetInThisCycle {
					didResetInThisCycle = true
					await resetAgentState(throttle: .seconds(1))
				}
				try? await Task.sleep(nanoseconds: 300_000_000)
				await _startStreaming(content: content, canRetry: false)
				return
			}
			// 401코드 사용자 메시지 매핑
			if let sseError = error as? AlanSSEClientError {
				switch sseError {
				case .badHTTPStatus(401):
					// 401: 인증/권한 실패 → 사용자 친화 메시지
					onError?("AI에서 응답 받는 것을 실패했습니다.\n나중에 다시 시도해 주세요.")
				default:
					// 그 외 SSE 오류는 기존 설명 사용
					onError?(sseError.errorDescription ?? "SSE 오류가 발생했습니다.")
				}
			} else {
				// 네트워크 일반 오류 등
				onError?("AI에서 응답 받는 것을 실패했습니다.")
			}
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
		do {
			_ = try await networkService.request(endpoint: ep, as: AlanResetStateResponse.self)
			Log.chat.info("reset-state success for clientID=\(self.clientID, privacy: .public)")
		} catch {
			Log.chat.error("reset-state failed: \(error.localizedDescription, privacy: .public)")
			onError?("세션 초기화 실패: \(error.localizedDescription)")
		}
	}
	
	
	// MARK: - DEBUG Mock Streaming
	private func startMockStreaming(_ content: String) {
		streamTask = Task { [weak self] in
			guard let self else { return }
			defer { self.onStreamCompleted?("") }
			
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
