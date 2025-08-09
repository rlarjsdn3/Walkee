//
//  LoadingResponseCell.swift
//  Health
//
//  Created by Seohyun Kim on 8/10/25.
//

import UIKit

final class LoadingResponseCell: CoreTableViewCell {
	private let indicator: CustomActivityIndicatorView = {
		let v = CustomActivityIndicatorView()
		v.translatesAutoresizingMaskIntoConstraints = false
		v.dotDiameter = 30
		v.color = .accent
		return v
	}()

	private let messageLabel: UILabel = {
		let lb = UILabel()
		lb.translatesAutoresizingMaskIntoConstraints = false
		lb.text = "응답을 생성 중입니다…"
		lb.textColor = .secondaryLabel
		lb.font = .preferredFont(forTextStyle: .callout)
		lb.numberOfLines = 0
		lb.adjustsFontForContentSizeCategory = true
		return lb
	}()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		MainActor.assumeIsolated {
			setupHierarchy()
			setupAttribute()
			setupConstraints()
		}
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		MainActor.assumeIsolated {
			setupHierarchy()
			setupAttribute()
			setupConstraints()
		}
	}

	// 문구/애니메이션 제어 메서드
	func configure(text: String? = nil, animating: Bool = true) {
		if let t = text { messageLabel.text = t }
		animating ? indicator.startAnimating() : indicator.stopAnimating()
		accessibilityLabel = messageLabel.text
	}

	// MARK: - CoreTableViewCell hooks
	override func setupHierarchy() {
		super.setupHierarchy()
		let hstack = UIStackView(arrangedSubviews: [indicator, messageLabel])
		hstack.axis = .horizontal
		hstack.alignment = .center
		hstack.spacing = 10
		hstack.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(hstack)
		
		indicator.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		indicator.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
		messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
		messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		messageLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		
		NSLayoutConstraint.activate([
			hstack.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
			hstack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -80),
			hstack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
			hstack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
			
			indicator.widthAnchor.constraint(equalToConstant: 22),
			indicator.heightAnchor.constraint(equalTo: indicator.widthAnchor)
		])
		
		let screenWidth = UIScreen.main.bounds.width
		let maxTextWidth: CGFloat

		switch screenWidth {
		case ...320:        // iPhone SE 1세대 이하
			maxTextWidth = 240
		case 321...375:     // iPhone 8, SE 2세대
			maxTextWidth = 280
		case 376...414:     // iPhone 8 Plus, 11
			maxTextWidth = 320
		default:            // iPhone 12 Pro Max 이상
			maxTextWidth = 350
		}
		
		let maxWidthConstraint = hstack.widthAnchor.constraint(
			lessThanOrEqualToConstant: maxTextWidth + 22 + 10
		)
		maxWidthConstraint.priority = .defaultHigh
		maxWidthConstraint.isActive = true
	}

	override func setupAttribute() {
		super.setupAttribute()
		selectionStyle = .none
		backgroundColor = .clear
		contentView.backgroundColor = .clear
		isAccessibilityElement = true
		accessibilityTraits.insert(.updatesFrequently)
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		messageLabel.text = "응답을 생성 중입니다…"
		indicator.startAnimating()
	}
}
