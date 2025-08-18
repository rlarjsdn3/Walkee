//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit
import Network
import os
/// Alan ai 활용한 챗봇 화면 컨트롤러.
///
@MainActor
final class ChatbotViewController: CoreGradientViewController {
	// MARK: - Outlets & Dependencies
	@Injected(default: AlanViewModel()) private var viewModel: AlanViewModel
	
	//private let headerView = ChatbotHeaderTitleView()
	private var headerHeight: CGFloat = 64   // 필요시 64~80 조정
	
	@IBOutlet weak var headerView: ChatbotHeaderTitleView!
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var containerViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var chattingInputStackView: UIStackView!
	@IBOutlet private weak var chattingContainerStackView: UIStackView!
	@IBOutlet private weak var chattingTextField: UITextField!
	@IBOutlet private weak var sendButton: UIButton!
	
	// MARK: 로그 확인용 및 마스킹 적용 PrivacyService 주입
	@Injected(.privacyService) private var privacy: PrivacyService
	
	// MARK: - Properties & States
	/// 현재 대화에 표시되는 메시지 목록
	private var messages: [ChatMessage] = []
	/// 고정 헤더 챗봇 타이틀
	private let hasFixedHeader = true
	/// 네트워크 상태
	private var networkStatusObservationTask: Task<Void, Never>?
	// MARK: - Keyboard State
	private let keyboardObserver = KeyboardObserver()
	/// 현재 키보드 높이
	private var currentKeyboardHeight: CGFloat = 0
	/// 직전 키보드 높이 — 최초 present 여부 판단에 사용
	private var previousKeyboardHeight: CGFloat = 0
	/// 키보드와 입력창 사이에 둘 여유 버퍼
	private let bottomBuffer: CGFloat = 8
	/// 응답 관련 속성
	private var focusLatestAIHead = false
	private var isWaitingResponse = false
	private var waitingHintTask: Task<Void, Never>?
	/// SSE 속성
	private var sseClient: AlanSSEClient?
	private var streamingAIIndex: Int?
	private var lastUIUpdate: CFTimeInterval = CFAbsoluteTimeGetCurrent()
	private let minUIInterval: CFTimeInterval = 0.03  // 30ms 스로틀
	private var waitingIndexPath: IndexPath?
	private var currentWaitingText: String?
	
	private var coalesceBuffer = String()
	private var coalesceTask: Task<Void, Never>?
	private let coalesceInterval: UInt64 = 25_000_000 // 25ms
	
	private var lastRelayout: CFAbsoluteTime = 0
	private let relayoutMinInterval: CFTimeInterval = 0.05
	
	// 각주 관련 속성
	private var inFootnote = false
	private var pendingOpenBracket = false
	
	private var isRelayoutInProgress = false

	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		setupAttribute()
		setupConstraints()
		setupHeaderView()
		setupTableView()
		setupKeyboardObservers()
		setupTapGesture()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
	}
	
	/// 화면이 사라질 때 메모리 정리(Actor 격리 안전 영역)
	/// - Note: `deinit` 대신 여기서 Task 취소를 수행하여 Swift 6 경고를 제거
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		networkStatusObservationTask?.cancel()
		networkStatusObservationTask = nil
		
		sseClient?.disconnect()
		sseClient = nil
		
		// Keyboard Observer 중지
		keyboardObserver.stopObserving()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		// 키보드가 없을 때만 기본 inset 복원
		if currentKeyboardHeight == 0 {
			adjustTableInsets()
		}
	}
	
	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		adjustTableInsets(keyboardHeight: currentKeyboardHeight)
	}
	
	override func initVM() {
		super.initVM()
		bindViewModel()
	}
	
	// MARK: - UI Setup
	override func setupAttribute() {
		super.setupAttribute()
		
		if #available(iOS 13.0, *) {
			self.isModalInPresentation = true
		}
		
		applyBackgroundGradient(.midnightBlack)
		chattingTextField.autocorrectionType = .no
		chattingTextField.autocapitalizationType = .none
		if #available(iOS 11.0, *) {
			chattingTextField.smartQuotesType = .no
			chattingTextField.smartDashesType = .no
		}
		chattingTextField.delegate = self
		setupStackViewStyles()
		automaticallyAdjustsScrollViewInsets = false
	}
	
	private func setupHeaderView() {
		headerView.onCloseTapped = { [weak self] in
			self?.dismiss(animated: true)
		}
	}
	/// ViewModel의 이벤트를 바인딩
	/// - AI 응답이 도착하면 메시지를 추가하고 필요 시 스크롤
	private func bindViewModel() {
		viewModel.onActionText = { [weak self] text in
			guard let self else { return }
			Task { @MainActor in
				//Log.ui.info("received action text: '\(text, privacy: .public)'")
				self.updateWaitingCellText(text)
			}
		}
		
		// 스트림 청크
		viewModel.onStreamChunk = { [weak self] chunk in
			guard let self else { return }
			
			if self.streamingAIIndex == nil {
				let message = ChatMessage(text: "", type: .ai)
				self.streamingAIIndex = self.messages.count
				self.messages.append(message)
				let ip = self.indexPathForMessage(at: self.streamingAIIndex!)
				self.tableView.insertRows(at: [ip], with: .fade)
			}
			
			guard let idx = self.streamingAIIndex else { return }
			self.messages[idx].text.append(chunk)
			
			if let cell = self.tableView.cellForRow(at: self.indexPathForMessage(at: idx)) as? AIResponseCell {
				cell.appendText(chunk)
			}
		}
		
		viewModel.onStreamCompleted = { [weak self] in
			self?.finishStreamingUI()
		}
	}

	private func indexPathForMessage(at messageIndex: Int) -> IndexPath {
		return IndexPath(row: messageIndex, section: 0)
	}
	
	private func setupStackViewStyles() {
		chattingContainerStackView.layer.cornerRadius = 12
		chattingContainerStackView.layer.masksToBounds = true
		chattingContainerStackView.isLayoutMarginsRelativeArrangement = true
		chattingContainerStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
		
		chattingInputStackView.backgroundColor = .boxBg
		chattingInputStackView.layer.cornerRadius = 12
		chattingInputStackView.layer.masksToBounds = true
		chattingInputStackView.layer.borderColor = UIColor.buttonText.cgColor
		chattingInputStackView.layer.borderWidth = 1.0
		
		chattingTextField.backgroundColor = .clear
		chattingTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
		chattingTextField.leftViewMode = .always
		chattingTextField.attributedPlaceholder = NSAttributedString(
			string: "걸어봇에게 물어보세요.",
			attributes: [.foregroundColor: UIColor.buttonBackground.withAlphaComponent(0.5)]
		)
	}
	
	private func adjustTableInsets(keyboardHeight: CGFloat = 0) {
		let inputH = chattingContainerStackView.frame.height
		let bottomPadding: CGFloat = 32
		let bottomInset = (keyboardHeight > 0)
			? (keyboardHeight + inputH + bottomPadding)
			: (inputH + bottomPadding)
		//let topInset = headerHeight + 8
		tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
	}
	
	private func setupTableView() {
		tableView.delegate = self
		tableView.dataSource = self
		tableView.backgroundColor = .clear
		tableView.separatorStyle = .none
		tableView.keyboardDismissMode = .interactive
		
		if #available(iOS 17.0, *) {
			tableView.selfSizingInvalidation = .enabledIncludingConstraints
		}
		
		tableView.showsVerticalScrollIndicator = false
		tableView.contentInsetAdjustmentBehavior = .never
		tableView.estimatedRowHeight = 80
		tableView.rowHeight = UITableView.automaticDimension

		tableView.register(BubbleViewCell.nib, forCellReuseIdentifier: BubbleViewCell.id)
		tableView.register(AIResponseCell.nib, forCellReuseIdentifier: AIResponseCell.id)
		tableView.register(LoadingResponseCell.self, forCellReuseIdentifier: LoadingResponseCell.id)
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SpacerCell")
		
		adjustTableInsets()
	}

	private func setupTapGesture() {
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
	}
	
	// MARK: - Keyboard Handling
	/// 키보드 높이 변화를 감지해 레이아웃과 스크롤을 업데이트
	/// - 하이브리드 자동 스크롤 규칙:
	///   - **처음 present**: 무조건 최신 메시지로 스크롤
	///   - 그 외: near-bottom & not-dragging일 때만 스크롤
	private func setupKeyboardObservers() {
		keyboardObserver.startObserving { [weak self] payload in
			guard let self else { return }
			self.applyKeyboardChange(payload)
		}
	}
	
	/// 가장 최근 AI 응답 셀의 **첫 문장(=셀 상단)** 으로 스크롤
	private func scrollToTopOfLatestAIResponse(animated: Bool) {
		if let idx = streamingAIIndex {
			let ip = indexPathForMessage(at: idx)
			if tableView.numberOfRows(inSection: 0) > ip.row {
				tableView.layoutIfNeeded()
				tableView.scrollToRow(at: ip, at: .top, animated: animated)
				return
			}
		}
		if let lastAI = messages.lastIndex(where: { $0.type == .ai }) {
			let ip = indexPathForMessage(at: lastAI)
			if tableView.numberOfRows(inSection: 0) > ip.row {
				tableView.layoutIfNeeded()
				tableView.scrollToRow(at: ip, at: .top, animated: animated)
			}
		}
	}
	
	/// 상단 포커스를 유지해야 하는 상황이면 유지(사용자 드래깅 중이면 미동작)
	private func maintainAIFocusIfNeeded(animated: Bool = false) {
		guard focusLatestAIHead, !tableView.isDragging, !tableView.isDecelerating else { return }
		scrollToTopOfLatestAIResponse(animated: animated)
	}

	private func applyKeyboardChange(_ payload: KeyboardChangePayload) {
		let endFrame = CGRect(x: payload.endX, y: payload.endY, width: payload.endW, height: payload.endH)
		let height = view.convert(endFrame, from: nil).intersection(view.bounds).height
		
		let wasHidden = (currentKeyboardHeight == 0)
		let willShow  = (height > 0)
		let isFirstPresent = wasHidden && willShow
		
		previousKeyboardHeight = currentKeyboardHeight
		currentKeyboardHeight  = height
		
		UIView.animate(withDuration: payload.duration,
					   delay: 0,
					   options: UIView.AnimationOptions(rawValue: payload.curveRaw << 16))
		{
			self.updateInputContainerConstraint(forKeyboardHeight: height)
			self.view.layoutIfNeeded()
			self.adjustTableInsets(keyboardHeight: height)
		} completion: { _ in
			Task { @MainActor in
				try await Task.sleep(for: .milliseconds(40))
				if height > 0 {
					self.scrollToTopOfLatestAIResponse(animated: true)
				} else {
					// 키보드 숨김 시에는 기존 정책 유지: 필요하면 하단으로
					if isFirstPresent {
						self.scrollToBottomIfNeeded(force: true)
					} else {
						self.scrollToBottomIfNeeded()
					}
				}
			}
		}
	}
	
	/// 입력창 하단 제약을 키보드 높이에 맞춰 조정
	private func updateInputContainerConstraint(forKeyboardHeight h: CGFloat) {
		let safe = view.safeAreaInsets.bottom
		let isStackViewFirst = containerViewBottomConstraint.firstItem === chattingContainerStackView
		if h <= 0 {
			containerViewBottomConstraint.constant = isStackViewFirst ? -48 : 48
		} else {
			containerViewBottomConstraint.constant = isStackViewFirst ? -(h - safe) : (h - safe)
		}
	}
	
	// MARK: - Auto Scroll
	/// 필요 시만 또는 강제로 스크롤을 하단으로 이동
	private func scrollToBottomIfNeeded(force: Bool = false) {
		// 키보드가 보이면 강제라도 하단 스크롤 금지 (필요 시 주석 해제해서 강제 허용 가능)
		if currentKeyboardHeight > 0 { return }
		guard force || shouldAutoScroll() else { return }
		scrollToBottom()
	}
	
	/// 자동 스크롤 가능 여부 판단
	/// - 드래그/감속 중이면 false
	/// - 하단 근처인지 threshold로 판단
	private func shouldAutoScroll() -> Bool {
		if tableView.isDragging || tableView.isDecelerating { return false }
		// 키보드 보이면 자동 스크롤 하지 않음
		if currentKeyboardHeight > 0 { return false }
		return isNearBottom(threshold: 120)
	}
	
	private func isNearBottom(threshold: CGFloat) -> Bool {
		let visibleHeight = tableView.bounds.height
		- tableView.adjustedContentInset.top
		- tableView.adjustedContentInset.bottom
		let offsetY = tableView.contentOffset.y
		let maxVisibleY = offsetY + visibleHeight
		return maxVisibleY >= (tableView.contentSize.height - threshold)
	}
	
	/// tableView를 가장 하단 메시지로 스크롤
	private func scrollToBottom() {
		let totalRows = messages.count + (isWaitingResponse ? 1 : 0)
		guard totalRows > 0 else { return }
		let lastIndexPath = IndexPath(row: totalRows - 1, section: 0)
		tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
	}
	
	// MARK: - Actions
	@IBAction private func sendButtonTapped(_ sender: UIButton) {
		sendMessageStreaming()
	}
	
	// MARK: - Alan AI API - 응답값 관련 메서드
	/// **일반 질문 요청값** - `/api/v1/question` APIEndPoint로 사용자 메시지를 추가하고 서버로 전송
	/// - 전송 후에는 무조건 최신 메시지로 스크롤
	// MARK: - 실제 챗봇에서 사용하고 있는 SSE 응답 방식
	private func sendMessageStreaming() {
		guard let text = chattingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  !text.isEmpty else { return }
		//Log.ui.info("send tapped: '\(text, privacy: .public)'")
		// 사용자 버블
		messages.append(ChatMessage(text: text, type: .user))
		chattingTextField.text = ""
		let userIP = IndexPath(row: messages.count - 1, section: 0)
		tableView.insertRows(at: [userIP], with: .bottom)
		scrollToBottomIfNeeded(force: true)
		
		// 로딩
		sendButton.isEnabled = false
		sendButton.alpha = 0.5
		
		// 빈 AI 버블(스트림 대상)
		messages.append(ChatMessage(text: "", type: .ai))
		streamingAIIndex = messages.count - 1
		focusLatestAIHead = true
		let aiIndexPath = indexPathForMessage(at: streamingAIIndex!)
		tableView.insertRows(at: [aiIndexPath], with: .bottom)
		
		showWaitingCell()
		
		// 응답 시작 부분이 보이도록 상단 고정
		Task { @MainActor in
			try? await Task.sleep(for: .milliseconds(60))
			self.tableView.scrollToRow(at: aiIndexPath, at: .top, animated: true)
		}
		
		
		inFootnote = false
		pendingOpenBracket = false
		
		//  원문 vs 비식별화 로그
		let masked = PrivacyService.maskSensitiveInfo(in: text)
		// 강제로 print 출력 (릴리즈 모드에서도 확실히 출력)
		print("=== 마스킹 디버그 ===")
		print("[Chatbot] Original: \(text)")
		print("[Chatbot] Masked  : \(masked)")
		print("==================")
		
		// Log도 출력 (설정에 따라 다를 수 있음)
		Log.privacy.info("Original: \(text, privacy: .public)")
		Log.privacy.info("Masked  : \(masked, privacy: .public)")
		
		// 조건부 컴파일로 추가 디버그 정보
#if DEBUG
		print("[DEBUG] 디버그 모드에서 실행 중")
		print("[DEBUG] 마스킹 전 길이: \(text.count), 마스킹 후 길이: \(masked.count)")
#else
		print("[RELEASE] 릴리즈 모드에서 실행 중")
		print("[RELEASE] 마스킹 전 길이: \(text.count), 마스킹 후 길이: \(masked.count)")
#endif
		
		// SSE 시작
		viewModel.startStreamingQuestionWithAutoReset(masked)
	}
	
	// MARK: 각주 [^ number ^] 는 제거하는 메서드
	private func sanitizeStreamingPiece(_ s: String) -> String {
		guard s.isEmpty == false else { return s }
		var out = String()
		var i = s.startIndex
		
		// 이전 조각이 '[' 로 끝났고, 이번 조각이 '^' 로 시작하면 각주 진입
		if pendingOpenBracket {
			if s.first == "^" {
				inFootnote = true
				pendingOpenBracket = false
				i = s.index(after: i) // '^' 소비
			} else {
				// 각주 아님: 보류했던 '[' 출력
				out.append("[")
				pendingOpenBracket = false
			}
		}
		
		while i < s.endIndex {
			let ch = s[i]
			
			if inFootnote {
				// 각주 모드: ']' 나올 때까지 모두 버림
				if ch == "]" { inFootnote = false }
				i = s.index(after: i)
				continue
			}
			
			if ch == "[" {
				let next = s.index(after: i)
				if next < s.endIndex {
					if s[next] == "^" {
						// '[^' 발견 → 각주 모드 진입, 둘 다 소비
						inFootnote = true
						i = s.index(after: next)
						continue
					} else {
						// 일반 '['
						out.append("[")
						i = next
						continue
					}
				} else {
					// 조각 끝이 '[' 로 끝남 → 다음 조각에서 판단
					pendingOpenBracket = true
					break
				}
			}
			
			out.append(ch)
			i = s.index(after: i)
		}
		
		return out
	}
	
	private func stripAllFootnotes(in text: String) -> String {
		let pattern = #"\[\^[^\]]*\]"#
		let regex = try? NSRegularExpression(pattern: pattern)
		let range = NSRange(location: 0, length: (text as NSString).length)
		let result = regex?.stringByReplacingMatches(in: text, range: range, withTemplate: "") ?? text
		return result
	}
	
	private func startSSEStreaming(for prompt: String, targetIndexPath: IndexPath) {
		let url: URL
		do {
			url = try buildStreamingURL(content: prompt, clientID: AppConfiguration.clientID)
		} catch {
			finishStreamingUI()
			return
		}
		
		let client = AlanSSEClient()
		sseClient = client
		let stream = client.connect(url: url)
		
		Task { @MainActor in
			do {
				// 라벨 달아서 .complete 때 즉시 탈출
				streamLoop: for try await event in stream {
					switch event.type {
					case .action:
						// 로딩 셀 문구 갱신 (speak가 우선, 없으면 content)
						if let speak = event.data.speak ?? event.data.content, !speak.isEmpty {
							self.updateWaitingCellText(speak)
							//Log.ui.debug("waiting text -> '\(speak, privacy: .public)'")
						}
					case .continue:
						// 토큰 붙이기
						guard let aiIndex = self.streamingAIIndex else {
							// Log.ui.error("streamingAIIndex nil in .continue")
							continue
						}
						let raw = event.data.content ?? ""
						let piece = sanitizeStreamingPiece(raw)
						guard piece.isEmpty == false else { continue }
						
						if let cell = self.tableView.cellForRow(at: targetIndexPath) as? AIResponseCell {
							// 보이는 셀: 직접 append (깜빡임 최소화)
							cell.appendText(piece)
							self.messages[aiIndex].text += piece
							
							self.relayoutRowIfNeeded(targetIndexPath)
						} else {
							// 화면 밖: 모델 누적 + 스로틀 리로드
							self.messages[aiIndex].text += piece
							let now = CFAbsoluteTimeGetCurrent()
							if (now - self.lastUIUpdate) >= self.minUIInterval {
								self.lastUIUpdate = now
								UIView.performWithoutAnimation {
									self.tableView.reloadRows(at: [targetIndexPath], with: .none)
								}
							}
						}
						// 필요시 자동 스크롤
						self.maintainAIFocusIfNeeded()
					case .complete:

						break streamLoop
					}
				}
			} catch {
				print(error)
			}
			self.finishStreamingUI()
		}
	}

	// MARK: - 실시간 로딩 셀
	private func updateWaitingCellText(_ text: String) {
		currentWaitingText = text
		guard isWaitingResponse else { return }
		
		if let idx = waitingIndexPath,
		   let cell = tableView.cellForRow(at: idx) as? LoadingResponseCell {
			cell.configure(text: text, animating: true)
			relayoutRowIfNeeded(idx)
			return
		}
		
		// fallback: 혹시 재사용/가시성 타이밍 이슈면 visibleCells에서 찾아서 갱신
		for case let loading as LoadingResponseCell in tableView.visibleCells {
			loading.configure(text: text, animating: true)
			if let ip = tableView.indexPath(for: loading) { relayoutRowIfNeeded(ip) }
			return
		}
		
		// 화면 밖이면 조용히 리로드
		if let idx = waitingIndexPath {
			UIView.performWithoutAnimation {
				tableView.reloadRows(at: [idx], with: .none)
			}
		}
	}
	
	private func finishStreamingUI() {
		guard let aiIndex = streamingAIIndex else {
			cleanupStreamingState()
			return
		}
		
		let ip = indexPathForMessage(at: aiIndex)
		guard let cell = tableView.cellForRow(at: ip) as? AIResponseCell else {
			cleanupStreamingState()
			return
		}
		
		// 1) 타이핑 효과 종료
		cell.setTypewriterEnabled(false)
		
		// 2) 타이핑 완료 후 텍스트 정리 (Modern Concurrency)
		Task { @MainActor in
			try? await Task.sleep(for: .milliseconds(100))
			await finalizeAIResponse(cell: cell, aiIndex: aiIndex)
			cleanupStreamingState()
		}
	}
	
	@MainActor
	private func finalizeAIResponse(cell: AIResponseCell, aiIndex: Int) async {
		let originalText = messages[aiIndex].text
		let cleaned = stripAllFootnotes(in: originalText)
		// 텍스트 업데이트
		messages[aiIndex].text = cleaned
		cell.configure(with: cleaned)
		
		let ip = indexPathForMessage(at: aiIndex)
		relayoutRowIfNeeded(ip)
	}

	@MainActor
	private func cleanupStreamingState() {
		// UI 상태 복구
		sendButton.isEnabled = true
		sendButton.alpha = 1.0
		
		// 네트워크 정리
		sseClient?.disconnect()
		sseClient = nil
		
		// 각주 관련 상태 초기화
		inFootnote = false
		pendingOpenBracket = false
		
		// 대기 셀 제거
		removeWaitingCell()
		
		// 스크롤 및 포커스 해제
		scrollToTopOfLatestAIResponse(animated: true)
		focusLatestAIHead = false
		streamingAIIndex = nil
	}

	@MainActor
	private func removeWaitingCell() {
		let willDeleteWaitingIP: IndexPath? = isWaitingResponse ? waitingIndexPath : nil
		isWaitingResponse = false
		waitingIndexPath = nil
		currentWaitingText = nil
		
		guard let deleteIndexPath = willDeleteWaitingIP,
			  tableView.numberOfRows(inSection: 0) > deleteIndexPath.row else { return }
		
		tableView.performBatchUpdates {
			tableView.deleteRows(at: [deleteIndexPath], with: .fade)
		}
	}
	
	private func computeMessageIndex(for indexPath: IndexPath) -> Int? {
		if isWaitingResponse, let wait = waitingIndexPath, indexPath == wait { return nil }
		var idx = indexPath.row
		// 로딩 행이 메시지들 뒤에 오므로 idx 조정 불필요(안전상 처리)
		if isWaitingResponse, let wait = waitingIndexPath, indexPath.row > wait.row { idx -= 1 }
		guard idx >= 0 && idx < messages.count else { return nil }
		return idx
	}
	
	private func loadingIndexPath() -> IndexPath {
		return IndexPath(row: messages.count, section: 0)
	}
	
	@objc private func dismissKeyboard() {
		view.endEditing(true)
	}
	
	private func showWaitingCell() {
		currentWaitingText = currentWaitingText ?? "응답을 생성 중입니다. 조금만 더 기다려주세요.."
		
		guard !isWaitingResponse else { return }
		isWaitingResponse = true
		
		let index = loadingIndexPath()
		waitingIndexPath = index
		tableView.insertRows(at: [index], with: .fade)
		
		if let aiIndex = streamingAIIndex {
			let aiIP = indexPathForMessage(at: aiIndex)
			if focusLatestAIHead {
				tableView.scrollToRow(at: aiIP, at: .top, animated: true)
			} else if shouldAutoScroll() {
				tableView.scrollToRow(at: aiIP, at: .bottom, animated: true)
			}
		}
		
		waitingHintTask?.cancel()
		waitingHintTask = Task { @MainActor in
			try? await Task.sleep(nanoseconds: 8_000_000_000)
			
			guard currentWaitingText == nil else { return }
			
			guard isWaitingResponse,
				  let idx = waitingIndexPath,     //기록해둔 인덱스로 접근
				  let cell = tableView.cellForRow(at: idx) as? LoadingResponseCell
			else { return }
			
			cell.configure(text: currentWaitingText, animating: true)
			return
		}
	}
	
	private func relayoutRowIfNeeded(_ indexPath: IndexPath) {
		let now = CFAbsoluteTimeGetCurrent()
		guard now - lastRelayout >= relayoutMinInterval else { return }
		lastRelayout = now
		
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.setNeedsLayout()
			cell.layoutIfNeeded()
		}
		
		UIView.performWithoutAnimation {
			tableView.beginUpdates()
			tableView.endUpdates()
		}
		
		// 스트리밍 중 컨텐츠가 커질 때도 '첫 줄' 포커스 유지
		maintainAIFocusIfNeeded()
	}
	
	
	private func hideWaitingCell() {
		waitingHintTask?.cancel()
		waitingHintTask = nil
		guard isWaitingResponse else { return }
		isWaitingResponse = false
		defer { waitingIndexPath = nil }          //정리
		currentWaitingText = nil
		
		if let idx = waitingIndexPath,
		   tableView.numberOfRows(inSection: 0) > idx.row {
			tableView.deleteRows(at: [idx], with: .fade)
		} else {
			tableView.reloadData()
		}
	}
	
	//	viewDidDisappear에서 cancel처리 함 - Swift 6 경고 이슈로 그렇게 처리함
	// TODO: 그치만 정말 deinit을 설정하지 않아도 되는 것은 좀 더 검증이 차후 필요할 것 같음.
	//	deinit {
	//		NotificationCenter.default.removeObserver(self)
	//		networkStatusObservationTask?.cancel()
	//	}
	
	// URL 생성 유틸 — APIEndpoint.askStreaming 재사용
	private func buildStreamingURL(content: String, clientID: String) throws -> URL {
		let endpoint = APIEndpoint.askStreaming(content: content, clientID: clientID)
		var comps = URLComponents(url: endpoint.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
		comps?.queryItems = endpoint.queryItems
		guard let url = comps?.url else { throw NetworkError.badURL }
		return url
	}
}

// MARK: - UITableViewDataSource
extension ChatbotViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count + (isWaitingResponse ? 1 : 0)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if isWaitingResponse, let waitIdx = waitingIndexPath, indexPath == waitIdx {
			let cell = tableView.dequeueReusableCell(
				withIdentifier: LoadingResponseCell.id,
				for: indexPath
			) as! LoadingResponseCell
			cell.configure(text: currentWaitingText, animating: true)
			return cell
		}
		
		guard let messageIndex = computeMessageIndex(for: indexPath) else {
			return UITableViewCell()
		}
		let message = messages[messageIndex]
		
		// 메시지 타입별 셀 처리
		switch message.type {
		case .user:
			let cell = tableView.dequeueReusableCell(
				withIdentifier: BubbleViewCell.id,
				for: indexPath
			) as! BubbleViewCell
			cell.configure(with: message)
			return cell
			
		case .ai:
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: AIResponseCell.id,
				for: indexPath
			) as? AIResponseCell else {
				return UITableViewCell()
			}
			
			cell.configure(with: message.text)
			
			cell.onContentGrew = { [weak self] in
				guard let self = self else { return }
				guard !self.isRelayoutInProgress else { return }
				self.isRelayoutInProgress = true
				
				Task {
					await MainActor.run {
						self.relayoutRowIfNeeded(indexPath)
					}
					try? await Task.sleep(nanoseconds: 50_000_000)
					await MainActor.run {
						self.isRelayoutInProgress = false
					}
				}
			}
			return cell
		case .loading:
			let cell = tableView.dequeueReusableCell(
				withIdentifier: LoadingResponseCell.id,
				for: indexPath
			) as! LoadingResponseCell
			cell.configure(text: message.text, animating: true)
			return cell
		}
	}
}

// MARK: - UITableViewDelegate
extension ChatbotViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let result = UITableView.automaticDimension
		return result
	}
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		if isWaitingResponse, let wait = waitingIndexPath, indexPath == wait {
			return 80
		}
		
		let idx = min(indexPath.row, max(messages.count - 1, 0))
		if idx >= 0 && idx < messages.count {
			let message = messages[idx]
			let result: CGFloat
			switch message.type {
			case .ai:
				result = 120
				// AI 메시지의 경우 텍스트 길이에 따라 더 정확한 추정
				if message.text.count > 200 {
					let estimatedResult = max(200, CGFloat(message.text.count) * 0.5) // 대략적인 계산
					return estimatedResult
				}
			case .user: result = 60
			case .loading: result = 80
			}
			return result
		}
		return 60
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		focusLatestAIHead = false
	}
}

// MARK: - UITextFieldDelegate
extension ChatbotViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		sendMessageStreaming()
		return true
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		// 텍스트필드 편집 시작할 때 최신 메시지로 스크롤 해 줌.
		Task { @MainActor in
			try await Task.sleep(for: .milliseconds(300))
			self.scrollToTopOfLatestAIResponse(animated: true)
		}
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if string == ". " {
			if let current = textField.text,
			   let swiftRange = Range(range, in: current) {
				let prefix = current[..<swiftRange.lowerBound]
				let suffix = current[swiftRange.upperBound...]
				let replaced = String(prefix) + " " + String(suffix)
				textField.text = replaced
				
				let newCursorOffset = prefix.count + 1
				if let pos = textField.position(from: textField.beginningOfDocument, offset: newCursorOffset),
				   let tp = textField.textRange(from: pos, to: pos) {
					textField.selectedTextRange = tp
				}
			}
			return false
		}
		
		let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
		let hasText = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		
		Task { @MainActor in
			self.sendButton.alpha = hasText ? 1.0 : 0.6
			self.sendButton.isEnabled = hasText
		}
		return true
	}
}
