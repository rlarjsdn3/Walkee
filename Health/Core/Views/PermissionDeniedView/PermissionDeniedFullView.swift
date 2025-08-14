//
//  PermissionDeniedFullView.swift
//  WarningCautionView
//
//  Created by 김건우 on 8/13/25.
//

import UIKit

final class PermissionDeniedFullView: UIView {

    /// 'tapped' 알림 이름을 정의하여 탭 이벤트 발생 시 사용합니다.
    static let shouldPresentAlert = Notification.Name("shouldPresentAlert")

    private let imageContainerView = UIView()
    private let imageView = UIImageView()
    private let titleContainerView = UIView()
    private let titleLabel = UILabel()
    private let contentStackView = UIStackView()
    private let button = UIButton()

    var touchHandler: (() -> Void)?

    private var exclamationMarkImage: UIImage? = {
        var image = UIImage(systemName: "exclamationmark.triangle.fill")
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
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

        contentStackView.layoutIfNeeded()

        imageContainerView.layer.cornerCurve = .continuous
        imageContainerView.applyCornerStyle(.circular)

        titleContainerView.layer.cornerCurve = .continuous
        titleContainerView.applyCornerStyle(.circular)
    }

    private func commonInit() {
        backgroundColor = .clear

        imageContainerView.backgroundColor = .systemYellow.withAlphaComponent(0.15)
        imageContainerView.layer.cornerRadius = imageContainerView.frame.width / 2
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageContainerView.widthAnchor.constraint(equalToConstant: 64),
            imageContainerView.heightAnchor.constraint(equalToConstant: 64),
        ])

        imageView.image = exclamationMarkImage
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor)
        ])

        imageContainerView.addSubview(button)
        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor, constant: 0),
            button.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: 0),
            button.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 0),
            button.topAnchor.constraint(equalTo: imageContainerView.topAnchor, constant: 0),
        ])

        titleContainerView.backgroundColor = .systemYellow.withAlphaComponent(0.15)
        titleContainerView.layer.cornerRadius = titleContainerView.bounds.height / 2
        titleContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleContainerView.heightAnchor.constraint(equalToConstant: 24)
        ])

        titleLabel.text = "건강 데이터 접근 권한 없음"
        titleLabel.font = .systemFont(ofSize: 11, weight: .black)
        titleLabel.textColor = .systemYellow
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainerView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: titleContainerView.topAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: -6),
        ])

        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.alignment = .center
        contentStackView.addArrangedSubview(imageContainerView)
        contentStackView.addArrangedSubview(titleContainerView)

        addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addBlurEffect(.systemChromeMaterial)
    }

    @objc func handleButtonTap() {
        touchHandler?()
        NotificationCenter.default.post(name: Self.shouldPresentAlert, object: nil)
    }
}


#Preview {
    PermissionDeniedFullView()
}
