//
//  EndChatCell.swift
//  Health
//
//  Created by Seohyun Kim on 8/13/25.
//

import UIKit

final class EndChatCell: CoreTableViewCell {
	
	// MARK: - Properties
	var onEndChatTapped: (() -> Void)?

	private let contentStackView: UIStackView = {
		let stackView = UIStackView()
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .horizontal
		stackView.alignment = .center
		stackView.spacing = 8
		return stackView
	}()

	private let titleLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = UIFont.preferredFont(forTextStyle: .body)
		label.textColor = .systemGray
		label.text = "대화를 종료하시겠습니까?"
		return label
	}()

	private let endChatButton: UIButton = {
		let button = UIButton(type: .system)
		button.translatesAutoresizingMaskIntoConstraints = false
		var config = UIButton.Configuration.filled()
		config.title = "대화 종료"
		config.baseBackgroundColor = .accent
		config.baseForegroundColor = .white
		config.cornerStyle = .fixed
		config.background.cornerRadius = 12
		button.configuration = config
		button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
		return button
	}()

	// MARK: - Initialization

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupHierarchy()
		setupAttribute()
		setupConstraints()
		endChatButton.addTarget(self, action: #selector(endChatButtonTapped), for: .touchUpInside)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UI Setup

	override func setupAttribute() {
		super.setupAttribute()
		self.selectionStyle = .none
		self.backgroundColor = .clear
	}

	override func setupHierarchy() {
		super.setupHierarchy()
		contentView.addSubview(contentStackView)
		contentStackView.addArrangedSubview(titleLabel)
		contentStackView.addArrangedSubview(endChatButton)
	}

	override func setupConstraints() {
		super.setupConstraints()
		NSLayoutConstraint.activate([
			contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
			contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
			contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

			endChatButton.heightAnchor.constraint(equalToConstant: 36) // 버튼 높이 조절 (선택 사항)
		])
	}

	@objc private func endChatButtonTapped() {
		onEndChatTapped?()
	}
}
