//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit
import Network
import os


private extension Duration {
	var milliseconds: Double {
		let (s, attos) = components
		return Double(s) * 1000.0 + Double(attos) / 1e15
	}
}
/// Alan ai 활용한 챗봇 화면 컨트롤러.
@MainActor
final class ChatbotViewController: CoreGradientViewController {
	// MARK: - Outlets & Dependencies
	@Injected private var viewModel: ChatbotViewModel

	@IBOutlet weak var headerView: ChatbotHeaderTitleView!
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var containerViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var chattingInputStackView: UIStackView!
	@IBOutlet private weak var chattingContainerStackView: UIStackView!
	@IBOutlet weak var chattingInputContainer: UIStackView!
	@IBOutlet private weak var chattingTextField: UITextField!
	@IBOutlet weak var disclaimerLabel: UILabel!
	@IBOutlet private weak var sendButton: UIButton!
	
	// MARK: 로그 확인용 및 마스킹 적용 PrivacyService 주입
	@Injected(.privacyService) private var privacy: PrivacyService
	
	// MARK: - Properties & States
	/// 현재 대화에 표시되는 메시지 목록
	private var messages: [ChatMessage] = []
	/// 네트워크 상태
	private var networkStatusObservationTask: Task<Void, Never>?
	private var wasPreviouslyDisconnected: Bool = false
	// MARK: - Keyboard State
	private let keyboardObserver = KeyboardObserver()
	/// 현재 키보드 높이
	private var currentKeyboardHeight: CGFloat = 0
	/// 직전 키보드 높이 — 최초 present 여부 판단에 사용
	private var previousKeyboardHeight: CGFloat = 0
	/// 응답 관련 속성
	private var focusLatestAIHead = false
	private var isWaitingResponse = false
	private var waitingHintTask: Task<Void, Never>?
	/// SSE 속성
	private var sseClient: AlanSSEClient?
	private var streamingAIIndex: Int?
	private var waitingIndexPath: IndexPath?
	private var currentWaitingText: String?
	private var lastRelayout: CFAbsoluteTime = 0
	private let relayoutMinInterval: CFTimeInterval = 0.05
	// 각주 관련 속성
	private var inFootnote = false
	private var pendingOpenBracket = false
	
	private var isRelayoutInProgress = false
	// 코드 내에서 응답값 파싱 확인을 위한 속성
	private var e2eStart: ContinuousClock.Instant?
	private var ttfbLogged = false
	
	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		setupAttribute()
		setupConstraints()
		setupHeaderView()
		setupTableView()
		setupKeyboardObservers()
		setupTapGesture()
		observeNetworkStatusChanges()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
		
		let closing = isMovingToParent || isBeingDismissed
		Log.ui.info("ChatbotVC closing=\(closing, privacy: .public)")
		guard closing else { return }
		Log.ui.info("Closing detected -> reset session")
		viewModel.resetSessionOnExit()
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
		//automaticallyAdjustsScrollViewInsets = false
		tableView.contentInsetAdjustmentBehavior = .never
	}
	
	override func setupConstraints() {
		super.setupConstraints()
		chattingContainerStackView.isLayoutMarginsRelativeArrangement = true
		if #available(iOS 11.0, *) {
			chattingContainerStackView.directionalLayoutMargins =
			NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16)
		} else {
			chattingContainerStackView.layoutMargins =
			UIEdgeInsets(top: 8, left: 16, bottom: 12, right: 16)
		}
		
		chattingContainerStackView.spacing = 8
		
		chattingInputContainer.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			chattingInputContainer.leadingAnchor.constraint(
				equalTo: chattingContainerStackView.layoutMarginsGuide.leadingAnchor),
			chattingInputContainer.trailingAnchor.constraint(
				equalTo: chattingContainerStackView.layoutMarginsGuide.trailingAnchor)
		])
		
		disclaimerLabel?.numberOfLines = 0
		disclaimerLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
		disclaimerLabel?.setContentHuggingPriority(.required, for: .vertical)
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		
		chattingInputStackView.layer.borderWidth = BackgroundHeightUtils.calculateBorderWidth(for: traitCollection)
		
		if traitCollection.userInterfaceStyle == .dark {
			chattingInputStackView.layer.borderColor = UIColor.buttonText.cgColor
			chattingInputStackView.layer.borderWidth = 1
			chattingInputStackView.layer.shadowOpacity = 0
		} else {
			chattingInputStackView.layer.borderColor = UIColor.boxBgLightModeStroke.cgColor
			BackgroundHeightUtils.setupShadow(for: chattingInputStackView)
		}
	}
	
	private func observeNetworkStatusChanges() {
		networkStatusObservationTask = Task {
			for await isConnected in await NetworkMonitor.shared.networkStatusStream() {
				await MainActor.run {
					if isConnected {
						if wasPreviouslyDisconnected {
							showToastAboveKeyboard(
								type: .success,
								title: "네트워크 연결이 복구되었습니다.",
								message: "계속해서 대화를 이어가세요 😊",
								duration: 2.5,
								keyboardHeight: currentKeyboardHeight
							)
							wasPreviouslyDisconnected = false
						}
					} else {
						showToastAboveKeyboard(
							type: .warning,
							title: "네트워크 연결 상태를 확인해주세요.",
							message: "와이파이나 셀룰러 데이터 연결상태를 확인해주세요.",
							duration: 3.0,
							keyboardHeight: currentKeyboardHeight
						)
						wasPreviouslyDisconnected = true
					}
				}
			}
		}
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
				//self.updateWaitingCellText(text)
				self.updateWaitingCellState(.waiting(text))
			}
		}
		
		// 스트림 청크
		viewModel.onStreamChunk = { [weak self] chunk in
			guard let self else { return }
			
			if !ttfbLogged, let t0 = self.e2eStart {
				let ms = t0.duration(to: .now).milliseconds
				print(String(format: "ttfb: %.3f ms", ms))  // 첫 청크 도착까지
				ttfbLogged = true
			}
			
			if self.streamingAIIndex == nil {
				// 로딩 셀이 있던 자리(= messages.count)에서 AI 셀로 교체
				let insertRow = self.messages.count
				self.messages.append(ChatMessage(text: "", type: .ai))
				self.streamingAIIndex = self.messages.count - 1
				let aiIP = IndexPath(row: insertRow, section: 0)
				
				self.tableView.performBatchUpdates({
					if let waitIP = self.waitingIndexPath {
						self.tableView.deleteRows(at: [waitIP], with: .fade)
						self.waitingIndexPath = nil
						self.isWaitingResponse = false
					}
					self.tableView.insertRows(at: [aiIP], with: .fade)
				})
				
				if let cell = self.tableView.cellForRow(at: aiIP) as? AIResponseCell {
					cell.configure(with: "", isFinal: false)
				}
				
				// 교체 직후, 레이아웃 확정 후 AI 응답의 "첫 줄"로 초점
				Task { @MainActor in
					await self.scrollToRowTopAfterLayout(aiIP, animated: true)
				}
			}
			
			// 청크 반영
			guard let idx = self.streamingAIIndex else { return }
			let cleaned = FootnoteSanitizer.sanitize(
				chunk,
				inFootnote: &self.inFootnote,
				pendingOpenBracket: &self.pendingOpenBracket
			)
			self.messages[idx].text.append(cleaned)
			
			let ip = self.indexPathForMessage(at: idx)
			if let cell = self.tableView.cellForRow(at: ip) as? AIResponseCell {
				cell.appendText(cleaned)
			} else {
				// 화면 밖이면 레이아웃만 갱신
				UIView.performWithoutAnimation {
					self.tableView.reloadRows(at: [ip], with: .none)
				}
			}
			
			// 스트리밍 중 ‘꼬리 따라가기’ (사용자가 하단 근처에 있을 때만)
			if self.autoScrollMode == .following, self.isNearBottomAuto() {
				self.scrollToBottomAbsolute(animated: false)
			}
		}
		
		viewModel.onStreamCompleted = { [weak self] finalText in
			guard let self else { return }
			
			guard let idx = self.streamingAIIndex, idx < self.messages.count else {
				self.cleanupStreamingState()
				return
			}
			
			// 1. messages 배열의 해당 AI 메시지를 최종 텍스트로 업데이트
			let cleaned = FootnoteSanitizer.stripAllFootnotes(from: finalText)
			self.messages[idx].text = cleaned
			
			// 2. 해당 셀에 최종 렌더링 지시
			let ip = self.indexPathForMessage(at: idx)
			if let cell = self.tableView.cellForRow(at: ip) as? AIResponseCell {
				cell.configure(with: cleaned, isFinal: true)
				self.relayoutRowIfNeeded(ip)
			} else {
				// 셀이 화면 밖이면 reload
				UIView.performWithoutAnimation {
					self.tableView.reloadRows(at: [ip], with: .none)
				}
			}
			
			// 3. UI 상태 정리
			self.endE2E()
			self.cleanupStreamingState()
		}
		viewModel.onError = { [weak self] errorText in
			guard let self else { return }
			// 에러 처리: 로딩 셀에 에러 메시지 표시 후 상태 정리
			Task { @MainActor in
				//self.updateWaitingCellText(errorText)
				self.updateWaitingCellState(.error(errorText))
				try await Task.sleep(for: .seconds(2))
				self.endE2E()
				self.cleanupStreamingState()
			}
		}
	}
	// MARK: - 응답값 파싱 확인을 위한 함수 `startE2E` 와 `endE2E`
	/// 질문 전송 직전 호출
	private func startE2E() {
		e2eStart = .now
		ttfbLogged = false
	}
	
	/// 완료 콜백에서 총 소요시간(ms) 출력
	private func endE2E() {
		guard let t0 = e2eStart else { return }
		let ms = t0.duration(to: .now)
		print(String(format: "e2e: %.3f ms", ms.milliseconds))
		e2eStart = nil
	}

	private func indexPathForMessage(at messageIndex: Int) -> IndexPath {
		return IndexPath(row: messageIndex, section: 0)
	}
	
	private func setupStackViewStyles() {
		chattingContainerStackView.layer.cornerRadius = 0
		chattingContainerStackView.layer.masksToBounds = false
		chattingContainerStackView.isLayoutMarginsRelativeArrangement = false
		chattingContainerStackView.layoutMargins = .zero
		
		chattingInputStackView.backgroundColor = .boxBg
		chattingInputStackView.layer.cornerRadius = 12
		chattingInputStackView.layer.masksToBounds = true
		chattingInputStackView.layer.borderWidth = BackgroundHeightUtils.calculateBorderWidth(for: traitCollection)
		
		if traitCollection.userInterfaceStyle == .dark {
			chattingInputStackView.layer.borderColor = UIColor.buttonText.cgColor
			chattingInputStackView.layer.borderWidth = 1
			chattingInputStackView.layer.shadowOpacity = 0
		} else {
			chattingInputStackView.layer.borderColor = UIColor.boxBgLightModeStroke.cgColor
			BackgroundHeightUtils.setupShadow(for: chattingInputStackView)
		}
		
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
		
		tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
	}
	
	private func setupTableView() {
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
		tableView.register(LoadingResponseCell.self, forCellReuseIdentifier: LoadingResponseCell.id)
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
				self.view.layoutIfNeeded()
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
		if h > 0 {
			containerViewBottomConstraint.constant = -(h - safe)
		} else {
			containerViewBottomConstraint.constant = 0
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
	
	// 1) “행 상단으로” 절대 스크롤(첫 줄 보장)
	private func scrollToRowTopAbsolute(_ indexPath: IndexPath,
										extraTopPadding: CGFloat = 8,
										animated: Bool) {
		tableView.layoutIfNeeded()
		let insetTop = tableView.adjustedContentInset.top
		let insetBottom = tableView.adjustedContentInset.bottom
		let rect = tableView.rectForRow(at: indexPath)
		
		let minY = -insetTop
		let maxY = max(minY, tableView.contentSize.height - tableView.bounds.height + insetBottom)
		
		var targetY = rect.minY - insetTop - extraTopPadding
		targetY = min(max(targetY, minY), maxY)
		
		tableView.setContentOffset(CGPoint(x: 0, y: targetY), animated: animated)
	}
	
	// 2) “하단 유지” 절대 스크롤(꼬리 따라가기 전용)
	private func scrollToBottomAbsolute(animated: Bool) {
		tableView.layoutIfNeeded()
		let insetTop = tableView.adjustedContentInset.top
		let insetBottom = tableView.adjustedContentInset.bottom
		let contentH = tableView.contentSize.height
		let visibleH = tableView.bounds.height
		let minY = -insetTop
		let maxY = max(minY, contentH - visibleH + insetBottom)
		tableView.setContentOffset(CGPoint(x: 0, y: maxY), animated: animated)
	}
	
	private enum AutoScrollMode { case following, manual }
	private var autoScrollMode: AutoScrollMode = .following

	private func cancelOngoingScrollAnimations() {
		// tableView 애니메이션/감속 즉시 중단
		tableView.layer.removeAllAnimations()
		// UIKit이 내부적으로 유지 중인 애니메이션 중단 트릭
		tableView.setContentOffset(tableView.contentOffset, animated: false)
	}

	// 사용자가 손댔으면 자동 따라가기 해제
	func scrollViewWillBeginDraggingResignAuto(_ scrollView: UIScrollView) {
		autoScrollMode = .manual
	}
	private func isNearBottomAuto(threshold: CGFloat = 40) -> Bool {
		let insetTop = tableView.adjustedContentInset.top
		let insetBottom = tableView.adjustedContentInset.bottom
		let contentH = tableView.contentSize.height
		let visibleH = tableView.bounds.height
		let minY = -insetTop
		let maxY = max(minY, contentH - visibleH + insetBottom)
		return (maxY - tableView.contentOffset.y) < threshold
	}

	
	
	@MainActor
	private func scrollToBottomAfterLayout(animated: Bool) async {
		tableView.layoutIfNeeded()
		await Task.yield() // 다음 런루프에서 셀 높이/콘텐츠 사이즈 확정
		scrollToBottomAbsolute(animated: animated)
	}
	
	@MainActor
	private func scrollToRowTopAfterLayout(_ indexPath: IndexPath,
										   extraTopPadding: CGFloat = 8,
										   animated: Bool) async {
		tableView.layoutIfNeeded()
		await Task.yield() // 다음 런루프에서 행/콘텐츠 사이즈 확정
		guard indexPath.section < tableView.numberOfSections,
			  indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else { return }

		let insetTop = tableView.adjustedContentInset.top
		let insetBottom = tableView.adjustedContentInset.bottom
		let rect = tableView.rectForRow(at: indexPath)

		let minY = -insetTop
		let maxY = max(minY, tableView.contentSize.height - tableView.bounds.height + insetBottom)
		var targetY = rect.minY - insetTop - extraTopPadding
		targetY = min(max(targetY, minY), maxY)

		tableView.setContentOffset(CGPoint(x: 0, y: targetY), animated: animated)
	}
	// ======
	// MARK: - Actions
	@IBAction private func sendButtonTapped(_ sender: UIButton) {
		sendMessageStreaming()
	}
	
	// MARK: - Alan AI API - 응답값 관련 메서드
	/// **일반 질문 요청값** - `/api/v1/question/streaming` APIEndPoint로 사용자 메시지를 추가하고 서버로 전송
	/// - 전송 후에는 무조건 최신 메시지로 스크롤
	// MARK: - 실제 챗봇에서 사용하고 있는 SSE 응답 방식
	@MainActor
	private func sendMessageStreaming() {
		// 0) 입력값 정리
		guard let text = chattingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  !text.isEmpty else { return }
		
		// 1) 사용자 버블 추가
		messages.append(ChatMessage(text: text, type: .user))
		chattingTextField.text = ""
		
		let userIP = IndexPath(row: messages.count - 1, section: 0)
		
		// 테이블 반영 + 사용자 버블까지 먼저 스크롤
		tableView.performBatchUpdates({
			tableView.insertRows(at: [userIP], with: .none)
		}, completion: { [weak self] _ in
			guard let self else { return }
			
			// Concurrency로 한 프레임 뒤 안전 스크롤
			Task { @MainActor [weak self] in
				guard let self else { return }
				await self.scrollToRowAfterLayout(userIP, position: .bottom, animated: true)
			
				// 2) 로딩 상태 진입 (버튼 비활성화 + Waiting 셀 노출)
				self.sendButton.isEnabled = false
				self.sendButton.alpha = 0.5
				self.showWaitingCell()
				
				// showWaitingCell() 안에서 self.waitingIndexPath 가 설정됨
				if let wip = self.waitingIndexPath {
					//await self.scrollToRowAfterLayout(wip, position: .bottom, animated: true)
					await self.scrollToRowTopAfterLayout(wip, animated: true)
				}
				
				// 2-5) 스트리밍 동안은 아래 꼬리만 자연스럽게 따라가도록 설정
				self.autoScrollMode = .following
				// 기존 상단 유지 로직의 간섭 방지
				self.focusLatestAIHead = false
				
				// 3) 스트리밍 상태 플래그 초기화
				self.inFootnote = false
				self.pendingOpenBracket = false
				// 4) SSE 시작
				self.startE2E()
				self.viewModel.startPromptChatWithAutoReset(text)
			}
		})
	}
	/// 레이아웃이 실제 반영된 다음 안전하게 스크롤.
	/// - runloop 한 턴 양보(Task.yield) 후 인덱스 유효성 검증 → 스크롤
	@MainActor
	private func scrollToRowAfterLayout(_ indexPath: IndexPath,
										position: UITableView.ScrollPosition,
										animated: Bool) async {
		tableView.layoutIfNeeded()
		// 다음 runloop로 한 턴 양보(갱신 확정)
		await Task.yield()
		guard indexPath.section < tableView.numberOfSections,
			  indexPath.row < tableView.numberOfRows(inSection: indexPath.section)
		else { return }
		tableView.scrollToRow(at: indexPath, at: position, animated: animated)
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
	
	@MainActor
	private func updateWaitingCellState(_ state: WaitingCellState) {
		switch state {
		case .waiting(let text):
			currentWaitingText = text
			if let idx = waitingIndexPath,
			   let cell = tableView.cellForRow(at: idx) as? LoadingResponseCell {
				cell.configure(text: text, animating: true)
				relayoutRowIfNeeded(idx)
				return
			}
		case .error(let text):
			currentWaitingText = text
			if let idx = waitingIndexPath,
			   let cell = tableView.cellForRow(at: idx) as? LoadingResponseCell {
				cell.configure(text: text, animating: false)
				relayoutRowIfNeeded(idx)
				return
			}
		}
		
		// fallback: visibleCells 에서 찾거나 reload
		for case let loading as LoadingResponseCell in tableView.visibleCells {
			switch state {
			case .waiting(let text): loading.configure(text: text, animating: true)
			case .error(let text):   loading.configure(text: text, animating: false)
			}
			if let ip = tableView.indexPath(for: loading) { relayoutRowIfNeeded(ip) }
			return
		}
		
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
		let cleaned = FootnoteSanitizer.stripAllFootnotes(from: originalText)
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
		
		Task { @MainActor in
			//  (중요) 절대 스크롤 전에 먼저 모든 진행 중 애니메이션 중단
			//self.cancelOngoingScrollAnimations()
			   if let aiIndex = streamingAIIndex {
				   let aiIP = indexPathForMessage(at: aiIndex)
				   // 레이아웃 확정 후 AI 응답의 첫 줄로
				   await scrollToRowTopAfterLayout(aiIP, animated: true)
			   } else {
				   // 아직 AI 셀이 없으면 WIP 셀의 첫 줄로
				   await scrollToRowTopAfterLayout(index, animated: true)
			   }
		   }

		/*
		if let aiIndex = streamingAIIndex {
			let aiIP = indexPathForMessage(at: aiIndex)
			
			// 새 플로우에선 첫 줄 상단 정렬을 강제(부드럽게 보여주기)
			scrollToRowTopAbsolute(aiIP, animated: true)
//			if focusLatestAIHead {
//				tableView.scrollToRow(at: aiIP, at: .top, animated: true)
//			} else if shouldAutoScroll() {
//				tableView.scrollToRow(at: aiIP, at: .bottom, animated: true)
//			}
		} else {
			// streamingAIIndex가 아직 없으면 WIP 셀로라도 초점 이동
			scrollToRowTopAbsolute(index, animated: true)
		}
		*/
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
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ChatbotViewController: UITableViewDataSource, UITableViewDelegate {
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
			
			let isStreamingRow = (streamingAIIndex == messageIndex)
			// cell.configure(with: message.text)
			// 재사용 시에도 seed만 (이미 appendText가 실시간 추가)
			cell.configure(with: message.text, isFinal: !isStreamingRow)
			
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
	
	// MARK: - UITableViewDelegate
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let result = UITableView.automaticDimension
		return result
	}
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		if isWaitingResponse, let wait = waitingIndexPath, indexPath == wait {
			return 80
		}
		
		let idx = min(indexPath.row, max(messages.count - 1, 0))
		guard idx >= 0 && idx < messages.count else { return 60 }
		let message = messages[idx]
		
		switch message.type {
		case .ai:
			if message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
				return 44
			}
			// 텍스트 길이에 따른 기존 로직
			if message.text.count > 200 {
				return max(200, CGFloat(message.text.count) * 0.5)
			}
			return 120
		case .user:
			return 60
		case .loading:
			return 80
		}
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		//focusLatestAIHead = false
		autoScrollMode = .manual
	}
	
	// 아래쪽 근처로 돌아오면 다시 활성화
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if isNearBottomAuto() { autoScrollMode = .following }
	}
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
		if !willDecelerate, isNearBottomAuto() { autoScrollMode = .following }
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

