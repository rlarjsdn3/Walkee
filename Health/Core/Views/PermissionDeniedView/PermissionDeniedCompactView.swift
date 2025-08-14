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
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        containerView.backgroundColor = .systemYellow.withAlphaComponent(0.1)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalTo: heightAnchor),
            containerView.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0)
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
