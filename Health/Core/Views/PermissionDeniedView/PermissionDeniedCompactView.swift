//
//  PermissionDeniedCompactView.swift
//  WarningCautionView
//
//  Created by 김건우 on 8/14/25.
//

import UIKit

// TODO: - 조금 더 범용적으로 사용하도록 코드 리팩토링하기

final class PermissionDeniedCompactView: UIView {

    static let shouldPresentAlert = Notification.Name("shouldPresentAlert")

    private let imageView = UIImageView()
    private let containerView = UIView()
    private let button = UIButton()

    var symbomPointSize: CGFloat = 12 {
        didSet { self.setNeedsLayout() }
    }

    var touchHandler: (() -> Void)?

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
        imageView.image = exclamationMarkImage(symbomPointSize)
    }

    private func commonInit() {
        backgroundColor = .clear

        imageView.image = exclamationMarkImage(12)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        containerView.backgroundColor = traitCollection.userInterfaceStyle == .dark
        ? .systemYellow.withAlphaComponent(0.1) : .systemYellow.withAlphaComponent(0.3)
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

        registerForTraitChanges()
    }

    @objc func handleButtonTap() {
        touchHandler?()
        NotificationCenter.default.post(name: Self.shouldPresentAlert, object: nil)
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            if self.traitCollection.userInterfaceStyle == .dark {
                self.containerView.backgroundColor = .systemYellow.withAlphaComponent(0.1)
            } else {
                self.containerView.backgroundColor = .systemYellow.withAlphaComponent(0.3)
            }
        }
    }

    private func exclamationMarkImage(_ ptSize: CGFloat) -> UIImage? {
        let image = UIImage(systemName: "exclamationmark.triangle.fill")
        let config = UIImage.SymbolConfiguration(pointSize: ptSize, weight: .regular)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.systemYellow]))
        return image?.applyingSymbolConfiguration(config)
    }

}
