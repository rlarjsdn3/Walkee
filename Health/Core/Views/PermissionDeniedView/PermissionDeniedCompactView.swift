//
//  PermissionDeniedCompactView.swift
//  WarningCautionView
//
//  Created by 김건우 on 8/14/25.
//

import UIKit

final class PermissionDeniedCompactView: UIView {

    static let shouldPresentAlert = Notification.Name("shouldPresentAlert")

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let contentStackView = UIStackView()
    private let containerView = UIView()
    private let button = UIButton()

    var touchHandler: (() -> Void)?

    private var exclamationMarkImage: UIImage? = {
        var image = UIImage(systemName: "exclamationmark.triangle.fill")
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.systemYellow]))
        return image?.applyingSymbolConfiguration(config)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.applyCornerStyle(.circular)
    }

    private func commonInit() {
        backgroundColor = .clear

        imageView.image = exclamationMarkImage
        contentStackView.addArrangedSubview(imageView)

        titleLabel.text = "접근 권한 없음"
        titleLabel.font = .systemFont(ofSize: 11, weight: .black)
        titleLabel.textColor = .systemYellow
        contentStackView.addArrangedSubview(titleLabel)

        contentStackView.spacing = 4
        contentStackView.alignment = .center
        containerView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6),
        ])

        containerView.backgroundColor = .systemYellow.withAlphaComponent(0.1)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        containerView.addSubview(button)
        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
            button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
        ])
    }

    @objc func handleButtonTap() {
        touchHandler?()
        NotificationCenter.default.post(name: Self.shouldPresentAlert, object: nil)
    }
}
