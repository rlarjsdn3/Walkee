//
//  ChatbotViewModel.swift
//  Health
//
//  Created by Seohyun Kim on 8/19/25.
//

import Foundation
/// Alan SSE 기반 챗봇 ViewModel
///
/// `ChatbotViewModel`은 Alan API의 SSE(Server-Sent Events) 스트리밍을 활용해
/// 실시간으로 AI 응답을 수신하고, 마스킹·프롬프트 설계·세션 관리 로직을 캡슐화한다.
///
/// ## 개요
/// - 걷기/보행 건강 주제에 특화된 챗봇 스트리밍 관리
/// - `PrivacyService`로 민감정보 비식별화 후 서버에 질의
/// - 500 서버 오류 시 **자동 1회 리셋 후 재시도**
/// - 401 인증 실패 시 사용자 친화 에러 메시지 매핑
/// - SSE 이벤트(`action`, `continue`, `complete`)를 UI 콜백으로 전달
///
/// ## 주요 역할
/// - 프롬프트 빌드 및 스트리밍 요청 (`startPromptChatWithAutoReset`)
/// - 스트리밍 도중 세션 리셋 관리 (`resetAgentState`)
/// - 화면 종료 시 안전한 정리 (`resetSessionOnExit`)
/// - 유닛 테스트/디버그 환경을 위한 모킹 응답 지원 (`startMockStreaming`)
///
/// ## 사용 예시
/// ```swift
/// let viewModel = ChatbotViewModel()
/// viewModel.onFinalRender = { attributed in
///     textView.attributedText = attributed
/// }
/// viewModel.startPromptChatWithAutoReset("오늘 걸음수는 몇 보야?")
/// ```
@MainActor
final class ChatbotViewModel {
	// MARK: - Dependencies
	@Injected private var sseService: AlanSSEServiceProtocol
	@Injected private var networkService: NetworkService
	@Injected private var promptBuilderService: PromptBuilderService
	// MARK: - Output Handlers(UI 콜백)
	/// AI가 말로 안내하는 텍스트(action 이벤트)
	var onActionText: ((String) -> Void)?
	/// 스트리밍 중간 청크(`continue` 이벤트)
	var onStreamChunk: ((String) -> Void)?
	/// 최종 마크다운 렌더링 결과(`complete` 이벤트)
	var onFinalRender: ((NSAttributedString) -> Void)?
	/// 최종 plain 텍스트 결과(`complete` 이벤트)
	var onStreamCompleted: ((String) -> Void)?
	/// 오류 발생 시 사용자에게 표시할 메시지
	var onError: ((String) -> Void)?
	// MARK: - State
	private var streamTask: Task<Void, Never>?
	private var didResetInThisCycle = false
	private var clientID: String { AppConfiguration.clientID }
	/// SSE 수신 도중 누적되는 버퍼
	private var streamingBuffer: String = "" // 변경: 스트리밍 버퍼 추가
	
	/// 중복 reset 방지용 시간 기록
	private var lastResetAt: ContinuousClock.Instant?
	/// reset 진행 중 여부
	private var resetInFlight = false
	// MARK: - Lifecycle
	deinit { streamTask?.cancel() }
	
	
	/// 사용자의 원문 메시지를 받아 SSE 스트리밍 요청을 시작한다.
	///
	/// - NOTE: 내부적으로 민감정보를 마스킹 처리하고, 프롬프트를 생성한 뒤 Alan SSE API에 연결한다.
	/// - Parameter rawMessage: 사용자가 입력한 원문 메시지
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
	
	/// 채팅 화면이 닫힐 때 호출되는 세션 정리 메서드.
	/// - Note: 기존 SSE를 취소하고, 800ms 스로틀을 적용해 reset-state를 호출한다.
	func resetSessionOnExit() {
		streamTask?.cancel() // 열려있던 SSE 즉시 취소
		Log.chat.info("view exit detected > cancel SSE & call reset-state")
		Task { [weak self] in
			guard let self else { return }
			await self.resetAgentState(throttle: .milliseconds(800))
		}
	}
	
	// MARK: - Private Helpers
	
	/// Alan API reset-state 호출
	/// - Parameter throttle: 주어진 기간 내 중복 호출 방지 (예: `.seconds(1)`)
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
	/// SSE 스트리밍을 시작한다.
	/// - Parameters:
	///   - content: 서버로 전송할 프롬프트 문자열
	///   - canRetry: 서버 오류(500) 발생 시 자동 재시도 허용 여부
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
	/// 오류가 재시도 가능한지 판별한다.
	/// - Parameter error: SSE 에러 객체
	/// - Returns: 500/ContentType 오류일 경우 true
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
	/// 유닛 테스트/디버그 환경을 위한 모킹 스트리밍
	/// - Parameter content: 요청 프롬프트(마스킹 후)
	private func startMockStreaming(_ content: String) {
		streamTask = Task { [weak self] in
			guard let self else { return }

			// 1) 먼저 mock_ask_streaming_response.json 시도
			if let url = Bundle.main.url(forResource: "mock_ask_streaming_response", withExtension: "json"),
			   let data = try? Data(contentsOf: url) {

				// 단일 객체 or 배열 모두 허용
				if let single = try? JSONDecoder().decode(AlanStreamingResponse.self, from: data) {
					handleMockEvent(single)
					return
				} else if let array = try? JSONDecoder().decode([AlanStreamingResponse].self, from: data) {
					for e in array { handleMockEvent(e) }
					return
				}
				// 포맷이 맞지 않으면 구형 파일로 폴백
			}

			// 2) 폴백: 기존 mock_ask_response.json (action + content)
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

				var buffer = ""
				for ch in mock.content {
					try await Task.sleep(nanoseconds: 30_000_000)
					let s = String(ch)
					buffer.append(s)
					self.onStreamChunk?(s)
				}

				let attributed = ChatMarkdownRenderer.renderFinalMarkdown(buffer)
				self.onFinalRender?(attributed)
				self.onStreamCompleted?(buffer)

			} catch {
				self.onError?(error.localizedDescription)
			}
		}

		// MARK: - Local helpers
		func handleMockEvent(_ e: AlanStreamingResponse) {
			switch e.type {
			case .action:
				if let s = e.data.speak ?? e.data.content, !s.isEmpty {
					self.onActionText?(s)
				}
			case .continue:
				if let c = e.data.content, !c.isEmpty {
					self.onStreamChunk?(c)
				}
			case .complete:
				let final = e.data.content ?? ""
				let attributed = ChatMarkdownRenderer.renderFinalMarkdown(final)
				self.onFinalRender?(attributed)
				self.onStreamCompleted?(final)
			}
		}
	}
}
