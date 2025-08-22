//
//  BubbleViewCell.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit

final class BubbleViewCell: CoreTableViewCell {
	@IBOutlet weak var bubbleView: UIView!
	@IBOutlet weak var promptMsgLabel: UILabel!
	
	@IBOutlet weak var bubbleTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var bubbleLeadingConstraint: NSLayoutConstraint!
	@IBOutlet weak var bubbleTrailingConstraint: NSLayoutConstraint!
	@IBOutlet weak var bubbleWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var bubbleBottomConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var labelTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var labelBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var labelLeadingConstraint: NSLayoutConstraint!
	@IBOutlet weak var labelTrailingConstraint: NSLayoutConstraint!
	
	private var appearanceChangeRegistration: UITraitChangeRegistration?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		MainActor.assumeIsolated {
			setupAttribute()
			applyBubbleStyle()
			registerTraitObservers()
		}
	}
	
	override func setupAttribute() {
		super.setupAttribute()
		
		selectionStyle = .none
		
		promptMsgLabel.textAlignment = .left
		promptMsgLabel.setContentHuggingPriority(.required, for: .vertical)
		promptMsgLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		
		bubbleView.layer.cornerRadius = 12
		bubbleView.clipsToBounds = true
		
		setupDynamicWidth()
	}
	
	override func setupConstraints() {
		super.setupConstraints()
		
		labelTopConstraint.constant = 12
		labelBottomConstraint.constant = 12
		labelLeadingConstraint.constant = 16
		labelTrailingConstraint.constant = 16
		
		bubbleTopConstraint.constant = 8
		bubbleBottomConstraint.constant = 8
		
		setupUserBubbleCorners()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		promptMsgLabel.text = nil
		applyBubbleStyle()
	}

	override func systemLayoutSizeFitting(
		_ targetSize: CGSize,
		withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
		verticalFittingPriority: UILayoutPriority
	) -> CGSize {
		setNeedsLayout()
		layoutIfNeeded()
		
		return super.systemLayoutSizeFitting(
			targetSize,
			withHorizontalFittingPriority: horizontalFittingPriority,
			verticalFittingPriority: verticalFittingPriority
		)
	}
	
	@available(iOS 17.0, *)
	private func registerTraitObservers() {
		appearanceChangeRegistration = registerForTraitChanges(
			[UITraitUserInterfaceStyle.self]
		) { (cell: BubbleViewCell, previous: UITraitCollection) in
			if cell.traitCollection.hasDifferentColorAppearance(comparedTo: previous) {
				cell.applyBubbleStyle()
			}
		}
	}

	/// 사용자 메시지로 셀 구성
	/// - Parameter text: 사용자가 입력한 메시지 텍스트
	func configure(with text: String) {
		promptMsgLabel.text = text
		updateBubbleWidth(for: text)
		setNeedsLayout()
		layoutIfNeeded()
	}
	
	/// ChatMessage 객체로 구성 (사용자 메시지만 처리)
	/// - Parameter message: 채팅 메시지 (user 타입만 처리)
	func configure(with message: ChatMessage) {
		guard message.type == .user else {
			print("BubbleViewCell은 사용자 메시지(.user)만 처리.")
			return
		}
		configure(with: message.text)
	}
	
	private func setupUserBubbleCorners() {
		bubbleView.layer.maskedCorners = [
			.layerMinXMinYCorner,
			.layerMinXMaxYCorner,
			.layerMaxXMaxYCorner
		]
	}
	
	private func applyBubbleStyle() {
		if traitCollection.userInterfaceStyle == .light {
			bubbleView.layer.borderWidth = 1
			bubbleView.layer.borderColor = UIColor.boxBgLightModeStroke.cgColor
			bubbleView.layer.shadowOpacity = 0
		} else {
			bubbleView.layer.borderWidth = 0
			bubbleView.layer.borderColor = nil
		}
	}
	
	/// 컨텐츠 기반 폭(constant) 설정
	/// - Parameter text: 텍스트
	private func updateBubbleWidth(for text: String) {
		let maxBubble = ChatbotWidthCalculator.maxBubbleWidth(
			for: .userBubble,
			horizontalContentPadding: 32
		)
		let contentMax = ChatbotWidthCalculator.maxContentWidth(for: .userBubble)
		let minWidth: CGFloat = 60
		
		// 텍스트 크기 계산
		let font = promptMsgLabel.font ?? UIFont.preferredFont(forTextStyle: .footnote)
		let textAttributes = [NSAttributedString.Key.font: font]
		let textRect = text.boundingRect(
			with: CGSize(width: contentMax, height: .greatestFiniteMagnitude),
			options: [.usesLineFragmentOrigin, .usesFontLeading],
			attributes: textAttributes,
			context: nil
		)
		
		// 필요한 너비 계산 (텍스트 너비 + 내부 패딩)
		let requiredWidth = textRect.width + 32
		let bubbleWidth = max(minWidth, min(maxBubble, requiredWidth))
		
		// 너비 제약 조건 업데이트
		bubbleWidthConstraint.constant = bubbleWidth
	}
	
	private func setupDynamicWidth() {
		let maxBubble = ChatbotWidthCalculator.maxBubbleWidth(
			for: .userBubble,
			horizontalContentPadding: 32
		)
		let minBubbleWidth: CGFloat = 60
		// 너비 제약 조건 우선순위
		bubbleWidthConstraint.priority = .init(999)
		// 최대 너비 제한
		let maxWidthConstraint = bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: maxBubble)
		maxWidthConstraint.priority = .defaultHigh
		maxWidthConstraint.isActive = true
		// 최소 너비 제한
		let minWidthConstraint = bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: minBubbleWidth)
		minWidthConstraint.priority = .defaultHigh
		minWidthConstraint.isActive = true
		
		bubbleTrailingConstraint.constant = 16
		bubbleTrailingConstraint.priority = .defaultHigh
		
		bubbleLeadingConstraint.priority = .init(250)
		bubbleLeadingConstraint.constant = 60
	}	
}
