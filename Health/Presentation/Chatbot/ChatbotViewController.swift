//
//  ChatbotViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit

class ChatbotViewController: CoreGradientViewController {
	
	@IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var chattingTextField: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupAttribute()
		
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
		
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tapGesture)
		
	}
	
	// TODO: 차후 챗봇 뷰모델 생성해서 넣을 예정
	override func initVM() {
		
	}
	
	override func setupHierarchy() {
		
	}
	
	override func setupAttribute() {
		applyBackgroundGradient(.midnightBlack)
		chattingTextField.autocorrectionType = .no
		
		setTextFieldAttribute()
	}
	
	private func setTextFieldAttribute() {
		chattingTextField.backgroundColor = .boxBg
		chattingTextField.layer.cornerRadius = 12
		chattingTextField.layer.masksToBounds = true
		chattingTextField.layer.borderColor = UIColor.buttonText.cgColor
		chattingTextField.layer.borderWidth = 1.0
		
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
	}
	
	@objc private func keyboardWillHide(notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
		
		textFieldBottomConstraint.constant = -48
		
		UIView.animate(withDuration: duration) {
			self.view.layoutIfNeeded()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}
