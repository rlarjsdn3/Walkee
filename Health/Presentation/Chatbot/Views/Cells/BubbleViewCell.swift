//
//  BubbleViewCell.swift
//  Health
//
//  Created by Nat Kim on 8/5/25.
//

import UIKit

final class BubbleViewCell: CoreTableViewCell {

	@IBOutlet weak var bubbleView: UIView!
	@IBOutlet weak var promptMsgLabel: UILabel!
	
	@IBOutlet weak var bubbleLeadingConstraint: NSLayoutConstraint!
	@IBOutlet weak var bubbleTrailingConstraint: NSLayoutConstraint!
	@IBOutlet weak var bubbleWidthConstraint: NSLayoutConstraint!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		MainActor.assumeIsolated {
			setupAttribute()
		}
    }
	
	override func setupAttribute() {
		super.setupAttribute()
		
		selectionStyle = .none
		
		bubbleView.layer.cornerRadius = 12
		bubbleView.clipsToBounds = true
		
		setupUserBubbleCorners()
		
	}
	
	private func setupUserBubbleCorners() {
		bubbleView.layer.maskedCorners = [
			.layerMinXMinYCorner,
			.layerMinXMaxYCorner,
			.layerMaxXMaxYCorner
		]
	}
	
	/// 사용자 메시지로 셀 구성
	/// - Parameter text: 사용자가 입력한 메시지 텍스트
	func configure(with text: String) {
		promptMsgLabel.text = text
		
		// 레이아웃 업데이트
		setNeedsLayout()
		layoutIfNeeded()
	}
	
	/// ChatMessage 객체로 구성 (사용자 메시지만 처리)
	/// - Parameter message: 채팅 메시지 (user 타입만 처리)
	func configure(with message: ChatMessage) {
		guard message.type == .user else {
			print("⚠️ BubbleViewCell은 사용자 메시지(.user)만 처리합니다.")
			return
		}
		
		configure(with: message.text)
	}
	
}
