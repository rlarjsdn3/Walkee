//
//  AIResponseCell.swift
//  Health
//
//  Created by Seohyun Kim on 8/7/25.
//

import UIKit

class AIResponseCell: CoreTableViewCell {

	@IBOutlet weak var responseTextView: UITextView!
	@IBOutlet weak var textViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
	
	override func setupAttribute() {
		super.setupAttribute()
		
		selectionStyle = .none
		responseTextView.textContainer.lineFragmentPadding = 0
		responseTextView.textContainerInset = .zero
		
		setupLeftAlignment()
	}
	
	private func setupLeftAlignment() {
		// 디바이스별 최대 너비 설정
		let screenWidth = UIScreen.main.bounds.width
		let maxTextWidth: CGFloat
		
		switch screenWidth {
		case ...320: // iPhone SE 1세대
			maxTextWidth = 240
		case 321...375: // iPhone 8, SE 2세대
			maxTextWidth = 280
		case 376...414: // iPhone 8 Plus, 11
			maxTextWidth = 320
		case 415...: // iPhone 12 Pro Max 이상
			maxTextWidth = 350
		default:
			maxTextWidth = min(280, screenWidth * 0.75)
		}
		
		textViewWidthConstraint.constant = maxTextWidth
		
		textViewTrailingConstraint.priority = .init(750)
	}
	
	func configure(with text: String) {
		responseTextView.text = text
		setNeedsLayout()
		layoutIfNeeded()
	}
	
}
