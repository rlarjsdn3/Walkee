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
	
	private let closeIconView: UIImageView = {
		let buttonImage = UIImageView(image: UIImage(systemName: "xmark"))
		buttonImage.translatesAutoresizingMaskIntoConstraints = false
		buttonImage.contentMode = .scaleAspectFit
		buttonImage.tintColor = .accent
		return buttonImage
	}()
	
	private lazy var closeButton: UIButton = {
		let button = UIButton()
		button.contentHorizontalAlignment = .center
		button.contentVerticalAlignment = .center
		button.tintColor = .accent
		button.addTarget(self, action: #selector(handleCloseButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
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
		closeButton.addSubview(closeIconView)
	}
	
	override func setupConstraints() {
		super.setupConstraints()
		
		let guide = safeAreaLayoutGuide
		
		NSLayoutConstraint.activate([
			chatbotImageView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
			chatbotImageView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
			chatbotImageView.widthAnchor.constraint(equalToConstant: 32),
			chatbotImageView.heightAnchor.constraint(equalToConstant: 32),
			
			welcomeLabel.leadingAnchor.constraint(equalTo: chatbotImageView.trailingAnchor, constant: 12),
			welcomeLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -12),
			welcomeLabel.centerYAnchor.constraint(equalTo: chatbotImageView.centerYAnchor),
			
			closeButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
			closeButton.topAnchor.constraint(equalTo: chatbotImageView.topAnchor),
			closeButton.widthAnchor.constraint(equalToConstant: 32),
			closeButton.heightAnchor.constraint(equalToConstant: 32),
	
			closeIconView.centerXAnchor.constraint(equalTo: closeButton.centerXAnchor),
			closeIconView.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
			closeIconView.widthAnchor.constraint(equalToConstant: 28),
			closeIconView.heightAnchor.constraint(equalTo: closeIconView.widthAnchor),
			
			bottomAnchor.constraint(greaterThanOrEqualTo: chatbotImageView.bottomAnchor, constant: 12)
		])
	}
	
	override func setupAttribute() {
		super.setupAttribute()
		chatbotImageView.layer.borderColor = UIColor.magenta.cgColor
		chatbotImageView.layer.borderWidth = 1
		
		closeIconView.layer.borderColor = UIColor.magenta.cgColor
		closeIconView.layer.borderWidth = 1
		
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
