//
//  ChatInputBarController.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit

final class ChatInputBarController: NSObject, UITextFieldDelegate {
	weak var textField: UITextField?
	weak var sendButton: UIButton?

	var onSend: ((String) -> Void)?

	init(textField: UITextField, sendButton: UIButton, attachesSendTarget: Bool = true) {
		self.textField = textField
		self.sendButton = sendButton
		super.init()
		setup(attachesSendTarget: attachesSendTarget)
	}

	private func setup(attachesSendTarget: Bool) {
		textField?.autocorrectionType = .no
		textField?.autocapitalizationType = .none
		if #available(iOS 11.0, *) {
			textField?.smartQuotesType = .no
			textField?.smartDashesType = .no
		}
		textField?.delegate = self
		if attachesSendTarget {
			sendButton?.addTarget(self, action: #selector(tapSend), for: .touchUpInside)
		}
		
		textField?.setPadding(left: 8)
	}

	@objc private func tapSend() {
		guard let t = textField?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  t.isEmpty == false else { return }
		onSend?(t)
	}

	func setEnabled(_ enabled: Bool) {
		sendButton?.isEnabled = enabled
		sendButton?.alpha = enabled ? 1.0 : 0.5
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		tapSend()
		return false
	}

	func clear() { textField?.text = "" }
}
