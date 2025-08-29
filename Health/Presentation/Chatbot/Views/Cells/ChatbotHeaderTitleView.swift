//
//  ChatbotHeaderTitleView.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit

final class ChatbotHeaderTitleView: CoreView {
	var onCloseTapped: (() -> Void)?
	
	private let chatbotImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.image = UIImage(named: "chatBot")
		imageView.contentMode = .scaleAspectFit
		imageView.clipsToBounds = true
		imageView.translatesAutoresizingMaskIntoConstraints = false
		return imageView
	}()
	
	private let welcomeLabel: UILabel = {
		let label = UILabel()
		label.text = "걸음에 대해 궁금한 점을 물어보세요."
		label.font = UIFont.preferredFont(forTextStyle: .body)
		label.textColor = .label
		label.numberOfLines = 0
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	private lazy var closeButton: UIButton = {
		var config = UIButton.Configuration.plain()
		config.image = UIImage(systemName: "xmark.circle.fill")
		config.baseForegroundColor = .secondaryLabel
		config.preferredSymbolConfigurationForImage =
		UIImage.SymbolConfiguration(pointSize: 26, weight: .regular, scale: .default)
		config.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
		
		let button = UIButton(configuration: config, primaryAction: nil)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.addTarget(self, action: #selector(handleCloseButtonTapped), for: .touchUpInside)
		button.imageView?.contentMode = .scaleAspectFit
		button.clipsToBounds = false
		button.imageView?.clipsToBounds = false
		return button
	}()
	
	// MARK: - Initialization
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupHierarchy()
		setupConstraints()
		setupAttribute()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		MainActor.assumeIsolated {
			setupHierarchy()
			setupConstraints()
			setupAttribute()
		}
	}
	
	// MARK: - Setup Methods
	override func setupHierarchy() {
		super.setupHierarchy()
		
		addSubview(chatbotImageView)
		addSubview(welcomeLabel)
		addSubview(closeButton)
	}
	
	override func setupConstraints() {
		super.setupConstraints()
		
		let guide = safeAreaLayoutGuide
		
		NSLayoutConstraint.activate([
			// ImageView - leading + centerY + size
			chatbotImageView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
			chatbotImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
			chatbotImageView.widthAnchor.constraint(equalToConstant: 28),
			chatbotImageView.heightAnchor.constraint(equalToConstant: 28),
			
			// Label - leading/trailing + centerY
			welcomeLabel.leadingAnchor.constraint(equalTo: chatbotImageView.trailingAnchor, constant: 12),
			welcomeLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -12),
			welcomeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
			
			// Close Button - trailing + centerY + size
			closeButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
			closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
			closeButton.widthAnchor.constraint(equalToConstant: 28),
			closeButton.heightAnchor.constraint(equalToConstant: 28)
		])
	}
	
	override func setupAttribute() {
		super.setupAttribute()
		backgroundColor = .clear
	}
	
	// MARK: - Configure Methods
	func configure(with text: String) {
		welcomeLabel.text = text
	}
	
	// MARK: - Actions
	@objc private func handleCloseButtonTapped() {
		onCloseTapped?()
	}
}
