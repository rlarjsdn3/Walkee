//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit
import Network


//private struct KeyboardChangePayload: Sendable {
//	let duration: Double
//	let curveRaw: UInt
//	let endX: Double
//	let endY: Double
//	let endW: Double
//	let endH: Double
//}
/// Alan 챗 화면 컨트롤러.
///
/// - 키보드 프레임 변화: **단일 노티(`keyboardWillChangeFrame`)**로 show/hide/패닝까지 처리
/// - 로직 분리: 입력창 제약 / 테이블 inset / 자동 스크롤 **역할 분리**
/// - 스크롤 정책 :
///   - **처음 키보드 present**, **메시지 전송**, **AI 응답 도착** → 강제 스크롤
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

	// MARK: - Data
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
		viewModel.didReceiveResponseText = { [weak self] text in
			guard let self else { return }
			Task { @MainActor in
				self.appendAIResponseAndScroll(text)
			}
		}
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
	
	@MainActor
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
	
	@MainActor
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
		sendMessage()
	}

	/// 사용자 메시지를 추가하고 서버로 전송
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
		tableView.insertRows(at: [index], with: .fade)
		
		if shouldAutoScroll() {
			tableView.scrollToRow(at: index, at: .top, animated: true)
		}

		waitingHintTask?.cancel()
		waitingHintTask = Task { @MainActor in
			try? await Task.sleep(nanoseconds: 8_000_000_000)
			guard isWaitingResponse,
				  let cell = tableView.cellForRow(at: index) as? LoadingResponseCell
			else { return }
			cell.configure(text: "응답을 생성하고 있어요. 조금만 더 기다려주세요…", animating: true)
		}
	}
	
	private func hideWaitingCell() {
		waitingHintTask?.cancel()
		waitingHintTask = nil
		guard isWaitingResponse else { return }
		isWaitingResponse = false

		let idx = loadingIndexPath()
		if tableView.numberOfRows(inSection: 0) > idx.row {
			tableView.deleteRows(at: [idx], with: .fade)
		} else {
			tableView.reloadData() // 안전망
		}
	}

//	viewDidDisappear에서 cancel처리 함 - Swift 6 경고 이슈로 그렇게 처리함
// TODO: 그치만 정말 deinit을 설정하지 않아도 되는 것은 좀 더 검증이 차후 필요할 것 같음.
//	deinit {
//		NotificationCenter.default.removeObserver(self)
//		networkStatusObservationTask?.cancel()
//	}
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
		if isWaitingResponse && indexPath.row == lastRow {
			let cell = tableView.dequeueReusableCell(withIdentifier: LoadingResponseCell.id, for: indexPath) as! LoadingResponseCell
			cell.configure()
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
			cell.configure(with: message.text)
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
		sendMessage()
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
