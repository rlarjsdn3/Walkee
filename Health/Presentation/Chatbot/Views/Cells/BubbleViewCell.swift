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
	
	override func awakeFromNib() {
        super.awakeFromNib()
		MainActor.assumeIsolated {
			setupAttribute()
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
		
		setupUserBubbleCorners()
		
	}
	
	override func setupConstraints() {
		super.setupConstraints()
		
		labelTopConstraint.constant = 12
		labelBottomConstraint.constant = 12
		labelLeadingConstraint.constant = 16
		labelTrailingConstraint.constant = 16
		
		bubbleTopConstraint.constant = 8
		bubbleBottomConstraint.constant = 8
		
		setupDynamicWidth()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		promptMsgLabel.text = nil
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
	
	/// 사용자 메시지로 셀 구성
	/// - Parameter text: 사용자가 입력한 메시지 텍스트
	func configure(with text: String) {
		promptMsgLabel.text = text
		
		updateBubbleWidth(for: text)
		
		setNeedsLayout()
		layoutIfNeeded()
	}
	
	
	
	private func setupUserBubbleCorners() {
		bubbleView.layer.maskedCorners = [
			.layerMinXMinYCorner,
			.layerMinXMaxYCorner,
			.layerMaxXMaxYCorner
		]
	}
	
	private func updateBubbleWidth(for text: String) {
		let screenWidth = UIScreen.main.bounds.width
		let maxWidth = screenWidth * 0.75 - 32 // 좌우 여백 고려
		let minWidth: CGFloat = 60
		
		// 텍스트 크기 계산
		let font = promptMsgLabel.font ?? UIFont.preferredFont(forTextStyle: .footnote)
		let textAttributes = [NSAttributedString.Key.font: font]
		
		let textRect = text.boundingRect(
			with: CGSize(width: maxWidth - 32, height: .greatestFiniteMagnitude), // 라벨 내부 패딩 고려
			options: [.usesLineFragmentOrigin, .usesFontLeading],
			attributes: textAttributes,
			context: nil
		)
		
		// 필요한 너비 계산 (텍스트 너비 + 내부 패딩)
		let requiredWidth = textRect.width + 32 // 좌우 패딩 16씩
		let bubbleWidth = max(minWidth, min(maxWidth, requiredWidth))
		
		// 너비 제약 조건 업데이트
		bubbleWidthConstraint.constant = bubbleWidth
	}
	
	private func setupDynamicWidth() {
		let screenWidth = UIScreen.main.bounds.width
		let maxBubbleWidth: CGFloat
		let minBubbleWidth: CGFloat = 60 // 최소 너비
		
		// 디바이스별 최대 너비 설정 (화면 너비의 75% 정도)
		switch screenWidth {
		case ...320: // iPhone SE 1세대
			maxBubbleWidth = 240
		case 321...375: // iPhone 8, SE 2세대
			maxBubbleWidth = 280
		case 376...414: // iPhone 8 Plus, 11
			maxBubbleWidth = 310
		case 415...: // iPhone 12 Pro Max 이상
			maxBubbleWidth = 340
		default:
			maxBubbleWidth = screenWidth * 0.75
		}
		
		// 너비 제약 조건 설정
		bubbleWidthConstraint.priority = .init(999)
		
		// 최대 너비 제한
		let maxWidthConstraint = bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: maxBubbleWidth)
		maxWidthConstraint.priority = .required
		maxWidthConstraint.isActive = true
		
		// 최소 너비 제한
		let minWidthConstraint = bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: minBubbleWidth)
		minWidthConstraint.priority = .required
		minWidthConstraint.isActive = true
		
		bubbleTrailingConstraint.constant = 16
		bubbleTrailingConstraint.priority = .required
		
		bubbleLeadingConstraint.priority = .init(250)
		bubbleLeadingConstraint.constant = 60 // 최소 여백
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
	
}
