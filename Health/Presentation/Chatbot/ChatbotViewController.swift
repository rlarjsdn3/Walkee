//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit

class ChatbotViewController: CoreGradientViewController {
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var chattingTextField: UITextField!
	@IBOutlet weak var sendButton: UIButton!
	
	private var messages: [ChatMessage] = []
	private let cellIdentifiers = (
		header: "HeaderTitleCell",
		bubble: "BubbleViewCell"
	)
	
	private let hasFixedHeader = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupAttribute()
		
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
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// UITextField를 맨 앞으로 가져오기
		view.bringSubviewToFront(chattingTextField)
		view.bringSubviewToFront(sendButton)
	}
	
	// TODO: 차후 챗봇 뷰모델 생성해서 넣을 예정
	override func initVM() {
		
	}
	
	override func setupHierarchy() {
		
	}
	
	override func setupAttribute() {
		applyBackgroundGradient(.midnightBlack)
		chattingTextField.autocorrectionType = .no
		chattingTextField.delegate = self
		
		setTextFieldAttribute()
	}
	
	@IBAction func sendButtonTapped(_ sender: UIButton) {
		sendMessage()
	}
	
	
	private func setupTableView() {
		tableView.delegate = self
		tableView.dataSource = self
		tableView.backgroundColor = .clear
		tableView.separatorStyle = .none
		tableView.keyboardDismissMode = .interactive
		
		// 동적 높이를 위한 설정
		tableView.estimatedRowHeight = 60
		tableView.rowHeight = UITableView.automaticDimension
		
		// 입력창 공간 확보를 위한 content inset
		tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 80, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
		
		// 셀 등록
		// HeaderTitleCell - 코드로 구성된 셀
		tableView.register(HeaderTitleCell.self, forCellReuseIdentifier: cellIdentifiers.header)
		
		// BubbleViewCell - XIB로 구성된 셀
		let bubbleNib = UINib(nibName: cellIdentifiers.bubble, bundle: nil)
		tableView.register(bubbleNib, forCellReuseIdentifier: cellIdentifiers.bubble)
	}
	
	private func setTextFieldAttribute() {
		chattingTextField.backgroundColor = .boxBg
		chattingTextField.layer.cornerRadius = 12
		chattingTextField.layer.masksToBounds = true
		chattingTextField.layer.borderColor = UIColor.buttonText.cgColor
		chattingTextField.layer.borderWidth = 1.0
		
		chattingTextField.isUserInteractionEnabled = true
		chattingTextField.isEnabled = true
		
		chattingTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: chattingTextField.frame.height))
		chattingTextField.leftViewMode = .always
		chattingTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: chattingTextField.frame.height))
		chattingTextField.rightViewMode = .always
		
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
		textFieldBottomConstraint.constant = -keyboardHeight - 8

		UIView.animate(withDuration: duration) {
			self.view.layoutIfNeeded()
		}
		
		Task { @MainActor in
			do {
				try await Task.sleep(for: .milliseconds(100))
				scrollToBottom()
			} catch {
				print("error", error)
			}
		}
	}
	
	@objc private func keyboardWillHide(notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
		
		textFieldBottomConstraint.constant = -48
		
		tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 80, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
		
		UIView.animate(withDuration: duration) {
			self.view.layoutIfNeeded()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
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
			let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifiers.header, for: indexPath) as! HeaderTitleCell
			cell.configure(with: "걸음에 대해 궁금한 점을 물어보세요.")
			return cell
		}
		
		// 사용자 메시지 처리
		let messageIndex = hasFixedHeader ? indexPath.row - 1 : indexPath.row
		let message = messages[messageIndex]
		
		// 현재는 사용자 메시지만 처리
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifiers.bubble, for: indexPath) as! BubbleViewCell
		cell.configure(with: message)
		return cell
	}
}

// MARK: - UITableViewDelegate
extension ChatbotViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		// HeaderTitleCell은 조금 더 큰 높이 예상
		if hasFixedHeader && indexPath.row == 0 {
			return 80
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
			do {
				try await Task.sleep(for: .milliseconds(300))
				scrollToBottom()
			} catch {
				print("error", error)
			}
		}
	}
}
