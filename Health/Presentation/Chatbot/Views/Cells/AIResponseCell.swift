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
		let maxTextWidth = ChatbotWidthCalculator.maxContentWidth(for: .aiResponseText)
		textViewWidthConstraint.constant = maxTextWidth
		textViewTrailingConstraint.priority = .init(750)
	}
	
	func configure(with text: String) {
		responseTextView.text = text
		setNeedsLayout()
		layoutIfNeeded()
	}
}
