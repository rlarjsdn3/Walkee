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
		v.dotDiameter = 22
		v.color = .accent
		return v
	}()

	private let messageLabel: UILabel = {
		let lb = UILabel()
		lb.translatesAutoresizingMaskIntoConstraints = false
		lb.text = ""
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
		let willShow = (text?.isEmpty == false)
		if willShow {
			messageLabel.isHidden = false
			messageLabel.text = text
		} else {
			messageLabel.isHidden = true
			messageLabel.text = nil
		}
		animating ? indicator.startAnimating() : indicator.stopAnimating()
		accessibilityLabel = messageLabel.isHidden ? "로딩 중" : messageLabel.text
		
		// hidden 토글 직후 스택뷰 레이아웃을 강제로 갱신
		setNeedsLayout()
		contentView.setNeedsLayout()
		contentView.layoutIfNeeded()
//		Log.ui.debug("LoadingResponseCell.configure text='\(self.messageLabel.text ?? "", privacy: .public)' animation=\(animating, privacy: .public)")
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
			hstack.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor,
											constant: 16),
			hstack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.safeAreaLayoutGuide.trailingAnchor,
											 constant: -80),
			hstack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
			hstack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
			
			indicator.widthAnchor.constraint(equalToConstant: 22),
			indicator.heightAnchor.constraint(equalTo: indicator.widthAnchor)
		])
		
		let maxTextWidth = ChatbotWidthCalculator.maxContentWidth(for: .loadingText)
		let maxWidthConstraint = hstack.widthAnchor.constraint(lessThanOrEqualToConstant: maxTextWidth + 22 + 10)
		maxWidthConstraint.priority = .defaultHigh
		maxWidthConstraint.isActive = true
	}

	override func setupAttribute() {
		super.setupAttribute()
		selectionStyle = .none
		//messageLabel.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.1)
		backgroundColor = .clear
		contentView.backgroundColor = .clear
		isAccessibilityElement = true
		accessibilityTraits.insert(.updatesFrequently)
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		messageLabel.text = ""
		messageLabel.isHidden = true
		indicator.startAnimating()      
		
		accessibilityLabel = "로딩 중"
		//Log.ui.debug("LoadingResponseCell.prepareForReuse - reset complete")
	}
}
