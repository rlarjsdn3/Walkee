//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit
import Network
import os
/// Alan 챗 화면 컨트롤러.
///
/// - 키보드 프레임 변화: **단일 노티(`keyboardWillChangeFrame`)**로 show/hide/패닝까지 처리
/// - 로직 분리: 입력창 제약 / 테이블 inset / 자동 스크롤 **역할 분리**
/// - 스크롤 정책 :
///   - **처음 키보드 present**, **메시지 전송**, **AI 응답 도착** -> 강제 스크롤
///   - 그 외(키보드 이동/패닝) - 하단 근처 & 드래깅 아님일 때만 스크롤
@MainActor
final class ChatbotViewController: CoreGradientViewController {
	// MARK: - Outlets & Dependencies
	private let viewModel = AlanViewModel()

	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var containerViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var chattingInputStackView: UIStackView!
	@IBOutlet private weak var chattingContainerStackView: UIStackView!
	@IBOutlet private weak var chattingTextField: UITextField!
	@IBOutlet private weak var sendButton: UIButton!

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
	private var isWaitingResponse = false
	private var waitingHintTask: Task<Void, Never>?
	/// SSE 속성
	private var sseClient: AlanSSEClient?
	private var streamingAIIndex: Int?
	private var lastUIUpdate: CFTimeInterval = CFAbsoluteTimeGetCurrent()
	private let minUIInterval: CFTimeInterval = 0.03  // 30ms 스로틀
	private var waitingIndexPath: IndexPath?
	private var currentWaitingText: String?
	
	private var lastRelayout: CFAbsoluteTime = 0
	private let relayoutMinInterval: CFTimeInterval = 0.05
	
	private var inFootnote = false
	
	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		setupAttribute()
		setupConstraints()
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
			updateTableViewContentInset()
		}
	}

	override func initVM() {
		super.initVM()
		bindViewModel()
	}

	/// ViewModel의 이벤트를 바인딩
	/// - AI 응답이 도착하면 메시지를 추가하고 필요 시 스크롤
	private func bindViewModel() {
		// TODO: 일반 응답값 - 나중에 `일반 모드`, `빠른 응답모드` UIMenu로 만든다면 같이 사용 가능할 듯(임시 주석)
		/*
		viewModel.didReceiveResponseText = { [weak self] text in
			guard let self else { return }
			Task { @MainActor in
				self.appendAIResponseAndScroll(text)
			}
		}
		*/
		viewModel.onActionText = { [weak self] text in
			   self?.updateWaitingCellText(text)   // ← 로딩 셀 실시간 갱신
		   }

		   // (참고) 이미 있는 스트림 콜백들 예시
		viewModel.onStreamChunk = { [weak self] raw in
			guard let self else { return }
			let piece = self.sanitizeStreamingPiece(raw)
			if !piece.isEmpty { self.appendStreamPieceToAIResponseCell(piece) }
		}
		   viewModel.onStreamCompleted = { [weak self] in
			   self?.finishStreamingUI()
		   }
		
	}
	
	/// SSE로 들어온 텍스트 조각을 현재 스트리밍 중인 AI 응답 셀에 반영
	private func appendStreamPieceToAIResponseCell(_ piece: String) {
		guard let aiIndex = self.streamingAIIndex, piece.isEmpty == false else { return }
		let targetIndexPath = IndexPath(row: aiIndex, section: 0)

		if let cell = self.tableView.cellForRow(at: targetIndexPath) as? AIResponseCell {
			// 보이는 셀: 직접 붙여 깜빡임 최소화
			cell.appendText(piece)
			self.messages[aiIndex].text += piece
			relayoutRowIfNeeded(targetIndexPath)
//			Log.ui.debug("append visible +\(piece.count, privacy: .public) total=\(self.messages[aiIndex].text.count, privacy: .public)")
		} else {
			// 화면 밖: 모델만 누적 + 스로틀 리로드
			self.messages[aiIndex].text += piece
			let now = CFAbsoluteTimeGetCurrent()
			if (now - self.lastUIUpdate) >= self.minUIInterval {
				self.lastUIUpdate = now
				UIView.performWithoutAnimation {
					self.tableView.reloadRows(at: [targetIndexPath], with: .none)
				}
//				Log.ui.debug("reloadRows(throttled) total=\(self.messages[aiIndex].text.count, privacy: .public)")
			}
		}

		// 자동 스크롤 (필요 시)
		let before = tableView.contentOffset.y
		self.scrollToBottomIfNeeded()
		let after = tableView.contentOffset.y
		//if before != after { Log.ui.debug("auto-scrolled to bottom") }
	}


	// MARK: - UI Setup
	override func setupAttribute() {
		applyBackgroundGradient(.midnightBlack)
		chattingTextField.autocorrectionType = .no
		chattingTextField.delegate = self
		setupStackViewStyles()
		automaticallyAdjustsScrollViewInsets = false
	}

	private func setupStackViewStyles() {
		chattingContainerStackView.layer.cornerRadius = 12
		chattingContainerStackView.layer.masksToBounds = true
		chattingContainerStackView.isLayoutMarginsRelativeArrangement = true
		chattingContainerStackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

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

	private func setupTableView() {
		tableView.delegate = self
		tableView.dataSource = self
		tableView.backgroundColor = .clear
		tableView.separatorStyle = .none
		tableView.keyboardDismissMode = .interactive

		if #available(iOS 17.0, *) {
			tableView.selfSizingInvalidation = .enabledIncludingConstraints
		}

		tableView.contentInsetAdjustmentBehavior = .never
		tableView.estimatedRowHeight = 60
		tableView.rowHeight = UITableView.automaticDimension

		tableView.register(ChatbotHeaderTitleCell.self, forCellReuseIdentifier: ChatbotHeaderTitleCell.id)
		tableView.register(BubbleViewCell.nib, forCellReuseIdentifier: BubbleViewCell.id)
		tableView.register(AIResponseCell.nib, forCellReuseIdentifier: AIResponseCell.id)
		tableView.register(LoadingResponseCell.self, forCellReuseIdentifier: LoadingResponseCell.id)
		updateTableViewContentInset()
	}

	/// 키보드가 없을 때 적용하는 기본 inset 값 계산
	private func updateTableViewContentInset() {
		let inputContainerHeight = chattingContainerStackView.frame.height
		let bottomInset = max(inputContainerHeight + 32, 100)
		tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: bottomInset, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
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
	
	//@MainActor
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
					   options: UIView.AnimationOptions(rawValue: payload.curveRaw << 16)) {
			self.updateInputContainerConstraint(forKeyboardHeight: height)
			self.view.layoutIfNeeded()
			self.updateTableInsets(forKeyboardHeight: height)
		} completion: { _ in
			Task { @MainActor in
				try await Task.sleep(for: .milliseconds(40))
				if isFirstPresent {
					self.scrollToBottomIfNeeded(force: true)
				} else {
					self.scrollToBottomIfNeeded()
				}
			}
		}
	}
	
	//@MainActor
	private func onKeyboardFrameChanged(_ noti: Notification) {
		guard let info = noti.userInfo,
			  let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
			  let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
			  let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
		else { return }
		
		let height = view.convert(endFrame, from: nil).intersection(view.bounds).height

		let wasHidden = (currentKeyboardHeight == 0)
		let willShow  = (height > 0)
		let isFirstPresent = wasHidden && willShow

		previousKeyboardHeight = currentKeyboardHeight
		currentKeyboardHeight  = height

		UIView.animate(withDuration: duration,
					   delay: 0,
					   options: UIView.AnimationOptions(rawValue: curve << 16)) {
			self.updateInputContainerConstraint(forKeyboardHeight: height)
			self.view.layoutIfNeeded()
			self.updateTableInsets(forKeyboardHeight: height)
		} completion: { _ in
			Task { @MainActor in
				try await Task.sleep(for: .milliseconds(40))
				if isFirstPresent {
					self.scrollToBottomIfNeeded(force: true)
				} else {
					self.scrollToBottomIfNeeded()
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

	/// 키보드가 있을 때 tableView inset 업데이트 (입력창 + 버퍼 포함)
	private func updateTableInsets(forKeyboardHeight h: CGFloat) {
		if h <= 0 {
			updateTableViewContentInset()
			return
		}
		let inputH = chattingContainerStackView.frame.height
		let bottomInset = h + inputH + bottomBuffer
		tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: bottomInset, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
	}

	// MARK: - Auto Scroll
	/// 필요 시만 또는 강제로 스크롤을 하단으로 이동
	private func scrollToBottomIfNeeded(force: Bool = false) {
		guard force || shouldAutoScroll() else { return }
		scrollToBottom()
	}

	/// 자동 스크롤 가능 여부 판단
	/// - 드래그/감속 중이면 false
	/// - 하단 근처인지 threshold로 판단
	private func shouldAutoScroll() -> Bool {
		if tableView.isDragging || tableView.isDecelerating { return false }
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
		let totalRows = hasFixedHeader ? messages.count + 1 : messages.count
		guard totalRows > 0 else { return }
		let lastIndexPath = IndexPath(row: totalRows - 1, section: 0)
		tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
	}

	// MARK: - Actions
	@IBAction private func sendButtonTapped(_ sender: UIButton) {
		sendMessageStreaming()
	}
	
	// TODO: 확실하게 필요없어지면 삭제 예정
	/// 일반 질문 요청값 - `/api/v1/question` APIEndPoint로 사용자 메시지를 추가하고 서버로 전송
	/// - 전송 후에는 무조건 최신 메시지로 스크롤
	private func sendMessage() {
		guard let text = chattingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  !text.isEmpty else { return }

		messages.append(ChatMessage(text: text, type: .user))
		chattingTextField.text = ""

		let insertIndex = hasFixedHeader ? messages.count : messages.count - 1
		let indexPath = IndexPath(row: insertIndex, section: 0)
		tableView.insertRows(at: [indexPath], with: .bottom)
		scrollToBottomIfNeeded(force: true)

		sendButton.isEnabled = false
		sendButton.alpha = 0.5
		
		showWaitingCell()

		Task {
			await viewModel.sendQuestion(text)
			
			await MainActor.run {
				hideWaitingCell()
				sendButton.isEnabled = true
				sendButton.alpha = 1
				
				if let error = viewModel.errorMessage {
					appendAIResponseAndScroll(error)
					showToast(message: error)
				}
			}
		}
	}
	
	private func sendMessageStreaming() {
		guard let text = chattingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  !text.isEmpty else { return }
		//Log.ui.info("send tapped: '\(text, privacy: .public)'")
		// 사용자 버블
		messages.append(ChatMessage(text: text, type: .user))
		chattingTextField.text = ""
		let userRow = hasFixedHeader ? messages.count : messages.count - 1
		tableView.insertRows(at: [IndexPath(row: userRow, section: 0)], with: .bottom)
		scrollToBottomIfNeeded(force: true)
		
		// 로딩
		sendButton.isEnabled = false
		sendButton.alpha = 0.5
		
		// 빈 AI 버블(스트림 대상)
		messages.append(ChatMessage(text: "", type: .ai))
		streamingAIIndex = messages.count - 1
		let aiRow = hasFixedHeader ? messages.count : messages.count - 1
		let aiIndexPath = IndexPath(row: aiRow, section: 0)
		tableView.insertRows(at: [aiIndexPath], with: .bottom)
		
		//waitingIndexPath = loadingIndexPath()
		
//		Log.ui.info("insert AI(empty) row=\(aiRow, privacy: .public) idx=\(String(describing: self.streamingAIIndex), privacy: .public)")
		// 응답 시작 부분이 보이도록 상단 고정
		Task { @MainActor in
			try? await Task.sleep(for: .milliseconds(60))
			self.tableView.scrollToRow(at: aiIndexPath, at: .top, animated: true)
		}
		
		showWaitingCell()
		
		// SSE 시작
		startSSEStreaming(for: text, targetIndexPath: aiIndexPath)
	}
	
	private func sanitizeStreamingPiece(_ s: String) -> String {
		// 아주 단순한 상태머신: [^  ...  ] 블록 전체를 숨김
		if s.hasPrefix("[^") { inFootnote = true }
		
		if inFootnote {
			// ']'를 만날 때까지는 전부 버림
			if let close = s.firstIndex(of: "]") {
				inFootnote = false
				// '].\n\n' 같은 토큰을 만나면 ']' 뒤의 꼬리만 살려서 반환
				let tailStart = s.index(after: close)
				return String(s[tailStart...])
			} else {
				return "" // 아직 각주 영역: 통째로 무시
			}
		}
		return s
	}
	
	private func startSSEStreaming(for prompt: String, targetIndexPath: IndexPath) {
		let url: URL
		do {
			url = try buildStreamingURL(content: prompt, clientID: AppConfiguration.clientID)
			//Log.net.info("built streaming URL ok")
		} catch {
//			Log.net.error("buildStreamingURL error: \(String(describing: error), privacy: .public)")
			finishStreamingUI()
			return
		}

		let client = AlanSSEClient()
		sseClient = client
		let stream = client.connect(url: url)
//		Log.net.info("SSE connect started")

		Task { @MainActor in
			do {
				// 라벨 달아서 .complete 때 즉시 탈출
				streamLoop: for try await event in stream {
					switch event.type {

					case .action:
						// 로딩 셀 문구 갱신 (speak가 우선, 없으면 content)
						if let speak = event.data.speak ?? event.data.content, !speak.isEmpty {
							self.updateWaitingCellText(speak)
//							Log.ui.debug("waiting text -> '\(speak, privacy: .public)'")
						}

					case .continue:
						// 토큰 붙이기
						guard let aiIndex = self.streamingAIIndex else {
//							Log.ui.error("streamingAIIndex nil in .continue")
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
							
//							Log.ui.debug("append visible +\(piece.count, privacy: .public) total=\(self.messages[aiIndex].text.count, privacy: .public)")
						} else {
							// 화면 밖: 모델 누적 + 스로틀 리로드
							self.messages[aiIndex].text += piece
							let now = CFAbsoluteTimeGetCurrent()
							if (now - self.lastUIUpdate) >= self.minUIInterval {
								self.lastUIUpdate = now
								UIView.performWithoutAnimation {
									self.tableView.reloadRows(at: [targetIndexPath], with: .none)
								}
//								Log.ui.debug("reloadRows(throttled) total=\(self.messages[aiIndex].text.count, privacy: .public)")
							}
						}

						// 필요시 자동 스크롤
						let before = tableView.contentOffset.y
						self.scrollToBottomIfNeeded()
						let after = tableView.contentOffset.y
						//if before != after { Log.ui.debug("auto-scrolled to bottom") }

					case .complete:
						// 대부분의 서버가 전문을 재전송하므로 여기선 content를 무시하고 종료
//						Log.sse.info("received .complete -> break stream loop")
						break streamLoop
					}
				}
			} catch {
				print(error)
//				Log.net.error("stream loop error: \(String(describing: error), privacy: .public)")
			}
			self.finishStreamingUI()
//			Log.ui.info("finishStreamingUI() done")
		}
	}
	
	private func updateWaitingCellText(_ text: String) {
		currentWaitingText = text
		guard isWaitingResponse else { return }
		
		// 1) 기록된 인덱스 우선
		if let idx = waitingIndexPath,
		   let cell = tableView.cellForRow(at: idx) as? LoadingResponseCell {
			cell.configure(text: text, animating: true)
			return                                //성공 시 종료
		}
		
		// 2) 보이는 셀에서 찾기 (스크롤로 밀려난 경우 대비)
		for case let loading as LoadingResponseCell in tableView.visibleCells {
			loading.configure(text: text, animating: true)
			return
		}
		
		// 3) 안 보이면 해당 행만 조용히 리로드 (다음 페인트에 노출)
		if let idx = waitingIndexPath {
			UIView.performWithoutAnimation {
				tableView.reloadRows(at: [idx], with: .none)
			}
		}
		// 3) 그래도 못 찾으면 무시 (다음 턴에 보이면 갱신됨)
//		Log.ui.debug("updateWaitingCellText skipped (no loading cell visible)")
	}

	private func finishStreamingUI() {
		// 0) 스트리밍 중인 셀의 타자 효과 종료(잔여 큐 즉시 붙임)
		if let aiIndex = streamingAIIndex {
			let row = hasFixedHeader ? aiIndex + 1 : aiIndex
			let ip = IndexPath(row: row, section: 0)
			if let cell = tableView.cellForRow(at: ip) as? AIResponseCell {
				cell.setTypewriterEnabled(false) // 남아있던 큐는 지연 없이 마저 붙임
			}
		}
		
		// 1) 로딩셀/버튼/UI 상태 복구
		hideWaitingCell()
//		Log.ui.debug("hideWaitingCell()")
		sendButton.isEnabled = true
		sendButton.alpha = 1.0
		
		// 2) 스트리밍 상태 정리
		streamingAIIndex = nil
		
		// 3) SSE 연결 정리
		sseClient?.disconnect()
		sseClient = nil
	}
	
	// DEBUG 전용 목업 스트리밍(선택)
//    #if DEBUG
//	private func simulateDebugStreaming(into indexPath: IndexPath, text: String) {
//		let chunks = AlanStreamingResponse.debugChunks(for: text, chunkSize: 3)
//		Task { @MainActor in
//			for ev in chunks {
//				guard let aiIndex = self.streamingAIIndex else { break }
//				self.messages[aiIndex].text += ev.data.content
//				UIView.performWithoutAnimation {
//					self.tableView.reloadRows(at: [indexPath], with: .none)
//				}
//				self.scrollToBottomIfNeeded()
//				try? await Task.sleep(for: .milliseconds(30))
//				if ev.type == .complete { break }
//			}
//		}
//	}
//    #endif

	/// AI 응답을 추가될 때 '응답 시작 시점'
	private func appendAIResponseAndScroll(_ text: String) {
		messages.append(ChatMessage(text: text, type: .ai))
		let insertIndex = hasFixedHeader ? messages.count : messages.count - 1
		let indexPath = IndexPath(row: insertIndex, section: 0)

		if #available(iOS 17.0, *) {
			tableView.performBatchUpdates({
				tableView.insertRows(at: [indexPath], with: .bottom)
			}, completion: { _ in
				Task { @MainActor in
					try await Task.sleep(for: .milliseconds(50))
					self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
				}
			})
		} else {
			tableView.insertRows(at: [indexPath], with: .bottom)
			Task { @MainActor in
				try await Task.sleep(for: .milliseconds(100))
				self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
			}
		}
	}

	@objc private func dismissKeyboard() {
		view.endEditing(true)
	}
	
	private func loadingIndexPath() -> IndexPath {
		let row = (hasFixedHeader ? messages.count + 1 : messages.count)
		return IndexPath(row: row, section: 0)
	}
	
	private func showWaitingCell() {
		guard !isWaitingResponse else { return }
		isWaitingResponse = true
		
		let index = loadingIndexPath()
		waitingIndexPath = index
		tableView.insertRows(at: [index], with: .fade)
		
		if shouldAutoScroll() {
			tableView.scrollToRow(at: index, at: .top, animated: true)
		}

		waitingHintTask?.cancel()
		waitingHintTask = Task { @MainActor in
			try? await Task.sleep(nanoseconds: 8_000_000_000)
			guard isWaitingResponse,
				  let idx = waitingIndexPath,     //기록해둔 인덱스로 접근
				  let cell = tableView.cellForRow(at: idx) as? LoadingResponseCell
			else { return }
			cell.configure(text: "응답을 생성하고 있어요. 조금만 더 기다려주세요…", animating: true)
		}
	}
	
//	private func relayoutRowIfNeeded(_ indexPath: IndexPath) {
//		let now = CACurrentMediaTime()
//		if (now - lastUIUpdate) >= minUIInterval {    // minUIInterval = 0.02~0.03 권장
//			lastUIUpdate = now
//			UIView.performWithoutAnimation {
//				tableView.beginUpdates()   // 높이 재계산
//				tableView.endUpdates()
//			}
//		}
//	}
	private func relayoutRowIfNeeded(_ indexPath: IndexPath) {
		let now = CFAbsoluteTimeGetCurrent()
		guard now - lastRelayout >= relayoutMinInterval else { return }
		lastRelayout = now
		UIView.performWithoutAnimation {
			tableView.beginUpdates()
			tableView.endUpdates()
		}
		scrollToBottomIfNeeded()
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
		let base = hasFixedHeader ? messages.count + 1 : messages.count
		return isWaitingResponse ? base + 1 : base
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// 첫 번째 행은 HeaderTitleCell (고정)
		if hasFixedHeader && indexPath.row == 0 {
			let cell = tableView.dequeueReusableCell(
				withIdentifier: ChatbotHeaderTitleCell.id,
				for: indexPath
			) as! ChatbotHeaderTitleCell
			cell.configure(with: "걸음에 대해 궁금한 점을 물어보세요.")
			return cell
		}
		
		let lastRow = tableView.numberOfRows(inSection: 0) - 1
		if isWaitingResponse,
		   let waitIdx = waitingIndexPath,
		   indexPath == waitIdx {
			let cell = tableView.dequeueReusableCell(
				withIdentifier: LoadingResponseCell.id, for: indexPath
			) as! LoadingResponseCell
			cell.configure(text: currentWaitingText ?? "응답을 생성 중입니다…", animating: true)
			return cell
		}
		
		let messageIndex = hasFixedHeader ? indexPath.row - 1 : indexPath.row
		let message = messages[messageIndex]
		
		switch message.type {
		case .user:
			let cell = tableView.dequeueReusableCell(
				withIdentifier: BubbleViewCell.id,
				for: indexPath
			) as! BubbleViewCell
			cell.configure(with: message)
			return cell
			
		case .ai:
			let cell = tableView.dequeueReusableCell(
				withIdentifier: AIResponseCell.id,
				for: indexPath
			) as! AIResponseCell
			
			let messageIndex = hasFixedHeader ? indexPath.row - 1 : indexPath.row
			let isStreamingRow = (messageIndex == streamingAIIndex)
			
			cell.setTypewriterEnabled(isStreamingRow)     //스트리밍 셀만 타자기
			cell.charDelayNanos = 50_000_000              //속도 조절(원하면)
			cell.onContentGrew = { [weak self] in
				guard let self else { return }
				self.relayoutRowIfNeeded(indexPath)     // begin/endUpdates만
			}
			
			cell.configure(with: message.text)            // 지금까지 누적 텍스트
			return cell
		}
	}
}

// MARK: - UITableViewDelegate
extension ChatbotViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		if hasFixedHeader && indexPath.row == 0 {
			return 80
		}
		
		let messageIndex = hasFixedHeader ? indexPath.row - 1 : indexPath.row
		if messageIndex < messages.count {
			let message = messages[messageIndex]
			return message.type == .ai ? 120 : 60
		}
		
		return 60
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
			self.scrollToBottomIfNeeded(force: true)
		}
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
		let hasText = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		
		// Swift Concurrency로 UI 업데이트
		Task { @MainActor in
			self.sendButton.alpha = hasText ? 1.0 : 0.6
			self.sendButton.isEnabled = hasText
		}
		return true
	}
}
