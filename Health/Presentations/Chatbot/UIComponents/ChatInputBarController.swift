//
//  ChatInputBarController.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit
/// 채팅 입력창 컨트롤러
///
/// - 역할:
///   - 텍스트 입력 필드와 전송 버튼을 관리
///   - Return 키, 버튼 탭 모두 동일한 전송 동작으로 연결
@MainActor
final class ChatInputBarController: NSObject {
	weak var textField: UITextField?
	weak var sendButton: UIButton?
	/// 전송 시 호출되는 핸들러
	var onSend: ((String) -> Void)?
	/// - Parameters:
	///   - textField: 사용자 입력 필드
	///   - sendButton: 전송 버튼
	///   - attachesSendTarget: 버튼에 기본 target-action 연결 여부
	init(textField: UITextField, sendButton: UIButton, attachesSendTarget: Bool = true) {
		self.textField = textField
		self.sendButton = sendButton
		super.init()
		setup(attachesSendTarget: attachesSendTarget)
	}
	/// 입력창 스타일/속성 설정
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
	/// 전송 버튼 탭 핸들러
	@objc private func tapSend() {
		guard let t = textField?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  t.isEmpty == false else { return }
		onSend?(t)
	}
	/// 입력창과 버튼 활성화/비활성화
	/// - Parameter enabled: true면 사용 가능
	func setEnabled(_ enabled: Bool) {
		sendButton?.isEnabled = enabled
		sendButton?.alpha = enabled ? 1.0 : 0.5
	}
	/// 입력 필드 초기화
	func clear() { textField?.text = "" }
}

extension ChatInputBarController: UITextFieldDelegate {
	/// 키보드의 Return 키를 전송으로 동작시키기 위한 `UITextFieldDelegate`
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		tapSend()
		return false
	}
}
