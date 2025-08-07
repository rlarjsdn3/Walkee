//
//  ChatbotHeaderTitleCell.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit

final class ChatbotHeaderTitleCell: CoreTableViewCell {
	static let cellID = "ChatbotHeaderTitleCell"
	
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
	
	// MARK: - Initialization
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		MainActor.assumeIsolated {
			setupHierarchy()
			setupConstraints()
			setupAttribute()
		}
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
		
		contentView.addSubview(chatbotImageView)
		contentView.addSubview(welcomeLabel)
	}
	
	override func setupConstraints() {
		super.setupConstraints()
		
		NSLayoutConstraint.activate([
			chatbotImageView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
			chatbotImageView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 0),
			chatbotImageView.widthAnchor.constraint(equalToConstant: 48),
			chatbotImageView.heightAnchor.constraint(equalToConstant: 48),
			
			welcomeLabel.leadingAnchor.constraint(equalTo: chatbotImageView.trailingAnchor, constant: 16),
			welcomeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
			welcomeLabel.centerYAnchor.constraint(equalTo: chatbotImageView.centerYAnchor),
			
			contentView.bottomAnchor.constraint(greaterThanOrEqualTo: chatbotImageView.bottomAnchor, constant: 16),
			contentView.bottomAnchor.constraint(greaterThanOrEqualTo: welcomeLabel.bottomAnchor, constant: 16)
		])
	}
	
	override func setupAttribute() {
		super.setupAttribute()
		
		selectionStyle = .none
		backgroundColor = .clear
	}
	
	// MARK: - Configure Methods
	func configure(with text: String) {
		welcomeLabel.text = text
	}
	
}
