//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit
import Network

class ChatbotViewController: CoreGradientViewController {
	private let viewModel = AlanViewModel()
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var chattingInputStackView: UIStackView!
	@IBOutlet weak var chattingContainerStackView: UIStackView!
	@IBOutlet weak var chattingTextField: UITextField!
	@IBOutlet weak var sendButton: UIButton!
	
	private var messages: [ChatMessage] = []

	private let hasFixedHeader = true
	// 네트워크 상태 변화 구독을 위한 Task
	private var networkStatusObservationTask: Task<Void, Never>?
	
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
	
	override func initVM() {
		super.initVM()
		bindViewModel()
	}
	
	override func setupHierarchy() {
		
	}
	
	override func setupAttribute() {
		applyBackgroundGradient(.midnightBlack)
		chattingTextField.autocorrectionType = .no
		chattingTextField.delegate = self
		
		setupStackViewStyles()
		
		automaticallyAdjustsScrollViewInsets = false
	}
	
	@IBAction func sendButtonTapped(_ sender: UIButton) {
		sendMessage()
	}
	
	private func bindViewModel() {
		viewModel.didReceiveResponseText = { [weak self] responseText in
			guard let self = self else { return }
			Task { @MainActor in
				self.handleAIResponse(responseText)
			}
		}
	}
	
	private func handleAIResponse(_ responseText: String) {
		let aiMessage = ChatMessage(text: responseText, type: .ai)
		messages.append(aiMessage)
		
		let insertIndex = hasFixedHeader ? messages.count : messages.count - 1
		let indexPath = IndexPath(row: insertIndex, section: 0)
		tableView.insertRows(at: [indexPath], with: .bottom)
		
		scrollToBottom()
	}
	
	private func handleNetworkError(with error: Error) {
		let networkError: NetworkError
		
		if let castedError = error as? NetworkError {
			networkError = castedError
		} else if let urlError = error as? URLError {
			switch urlError.code {
			case .notConnectedToInternet:
				networkError = .notConnectedToInternet
			case .timedOut:
				networkError = .timedOut
			default:
				networkError = .requestFailed(urlError)
			}
		} else {
			// NetworkError로 캐스팅할 수 없는 경우, 알 수 없는 오류로 처리
			networkError = .unknown
		}
		
		let errorMessage = networkError.localizedDescription
		
		// 챗봇 응답으로 에러 메시지 추가
		let errorResponse = ChatMessage(text: errorMessage, type: .ai)
		messages.append(errorResponse)
		
		let insertIndex = hasFixedHeader ? messages.count : messages.count - 1
		let indexPath = IndexPath(row: insertIndex, section: 0)
		tableView.insertRows(at: [indexPath], with: .bottom)
		
		scrollToBottom()
		
		showToast(message: errorMessage)
	}
	
	/// NetworkMonitor를 사용해 네트워크 상태 변화 감지하고 토스트 메시지 표시하기 위함
	private func setupNetworkMonitoring() {
		networkStatusObservationTask = Task {
			do {
				for await isConnected in await NetworkMonitor.shared.networkStatusStream() {
					if isConnected {
						// 연결이 복구되었을 때 토스트 메시지 표시
						await MainActor.run {
							self.showToast(message: "네트워크 연결이 복구되었습니다.")
						}
					} else {
						// 연결이 끊겼을 때 토스트 메시지 표시
						let errorMessage = NetworkError.notConnectedToInternet.errorDetailMsgs
						await MainActor.run {
							self.showToast(message: errorMessage)
						}
					}
				}
			} catch {
				// 스트림 처리 중 오류 발생 시 (예: Task.cancel()로 인한 종료)
				print("네트워크 상태 스트림 오류: \(error.localizedDescription)")
			}
		}
	}
	
	private func setupTableView() {
		tableView.delegate = self
		tableView.dataSource = self
		tableView.backgroundColor = .clear
		tableView.separatorStyle = .none
		tableView.keyboardDismissMode = .interactive
		
		if #available(iOS 11.0, *) {
			tableView.contentInsetAdjustmentBehavior = .never
		}
		
		// 동적 높이를 위한 설정
		tableView.estimatedRowHeight = 60
		tableView.rowHeight = UITableView.automaticDimension
		
		// 입력창 공간 확보를 위한 content inset
		tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 80, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
		
		tableView
			.register(ChatbotHeaderTitleCell.self, forCellReuseIdentifier: ChatbotHeaderTitleCell.id)
		
		let bubbleNib = BubbleViewCell.nib
		tableView.register(bubbleNib, forCellReuseIdentifier: BubbleViewCell.id)
		
		let aiResponseNib = AIResponseCell.nib
		tableView.register(aiResponseNib, forCellReuseIdentifier: AIResponseCell.id)
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
		
		// TextField 설정
		chattingTextField.backgroundColor = .clear
		chattingTextField.isUserInteractionEnabled = true
		chattingTextField.isEnabled = true
		
		// 좌측 여백
		chattingTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
		chattingTextField.leftViewMode = .always
		
		let placeholderText = "걸어봇에게 물어보세요."
		let placeholderColor = UIColor.buttonBackground.withAlphaComponent(0.5)
		
		chattingTextField.attributedPlaceholder = NSAttributedString(
			string: placeholderText,
			attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
		)
	}
	
	private func setupKeyboardObservers() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(keyboardWillShow(notification:)),
			name: UIResponder.keyboardWillShowNotification,
			object: nil
		)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(keyboardWillHide(notification:)),
			name: UIResponder.keyboardWillHideNotification,
			object: nil
		)
	}
	
	private func setupTapGesture() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tapGesture)
	}
	
	private func sendMessage() {
		guard let text = chattingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  !text.isEmpty else { return }
		
		// 사용자 메시지 추가
		let userMessage = ChatMessage(text: text, type: .user)
		messages.append(userMessage)
		
		chattingTextField.text = ""
		
		// 테이블뷰 업데이트
		let insertIndex = hasFixedHeader ? messages.count : messages.count - 1
		let indexPath = IndexPath(row: insertIndex, section: 0)
		tableView.insertRows(at: [indexPath], with: .bottom)
		
		// 최신 메시지로 스크롤
		scrollToBottom()
		
		sendButton.isEnabled = false
		sendButton.alpha = 0.5
		
		// API 호출
		Task {
			await viewModel.sendQuestion(text)
			
			await MainActor.run {
				self.sendButton.isEnabled = true
				self.sendButton.alpha = 1
			}
			
			// Error타입인데, AlanViewModel에서 errorMessage를 String 타입으로 받음으로 별도로 string으로 처리
			if let errorMessageString = viewModel.errorMessage {
				let errorResponse = ChatMessage(text: errorMessageString, type: .ai)
				messages.append(errorResponse)
				
				let insertIndex = hasFixedHeader ? messages.count : messages.count - 1
				let indexPath = IndexPath(row: insertIndex, section: 0)
				tableView.insertRows(at: [indexPath], with: .bottom)
				
				scrollToBottom()
				showToast(message: errorMessageString)
			}
		}
	}
	
	private func scrollToBottom() {
		let totalRows = hasFixedHeader ? messages.count + 1 : messages.count
		guard totalRows > 0 else { return }
		
		let lastIndexPath = IndexPath(row: totalRows - 1, section: 0)
		tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
	}
	@objc private func dismissKeyboard() {
		view.endEditing(true)
	}
	
	@objc private func keyboardWillShow(notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
			  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
		
		let keyboardHeight = keyboardFrame.height
		let safeAreaBottomInset = view.safeAreaInsets.bottom
		
		// 제약조건 방향 확인
		let isStackViewFirst = containerViewBottomConstraint.firstItem === chattingContainerStackView
	
		if isStackViewFirst {
			let newConstant = -(keyboardHeight - safeAreaBottomInset + 16)
			containerViewBottomConstraint.constant = newConstant
			print("- new constant (StackView first): \(newConstant)")
		} else {
			let newConstant = keyboardHeight - safeAreaBottomInset + 16
			containerViewBottomConstraint.constant = newConstant
			print("- new constant (SafeArea first): \(newConstant)")
		}
		
		// TableView content inset 조정
		let tableBottomInset = keyboardHeight + 74
		tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: tableBottomInset, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
		
		UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) {
			self.view.layoutIfNeeded()
		} completion: { _ in
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				self.scrollToBottom()
			}
		}
	}
	
	@objc private func keyboardWillHide(notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
		
		let isStackViewFirst = containerViewBottomConstraint.firstItem === chattingContainerStackView
		
		if isStackViewFirst {
			containerViewBottomConstraint.constant = -48
		} else {
			containerViewBottomConstraint.constant = 48
		}
		
		tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 20, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
		
		UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) {
			self.view.layoutIfNeeded()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
		// 네트워크 상태 구독 Task 취소
		
		networkStatusObservationTask?.cancel()
	}
}

// MARK: - UITableViewDataSource
extension ChatbotViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// HeaderTitleCell(고정) + 사용자 메시지들
		return hasFixedHeader ? messages.count + 1 : messages.count
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
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			self.scrollToBottom()
		}
//		Task { @MainActor in
//			do {
//				try await Task.sleep(for: .milliseconds(300))
//				scrollToBottom()
//			} catch {
//				print("error", error)
//			}
//		}
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
