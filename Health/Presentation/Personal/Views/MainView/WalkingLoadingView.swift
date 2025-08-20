//
//  WalkingLoadingView.swift
//  Health
//
//  Created by juks86 on 8/20/25.
//

import UIKit

class WalkingLoadingView: UIView {

    enum State {
        case loading
        case failed
        case networkError
    }

    private let stackView = UIStackView()
    private let activityIndicator = CustomActivityIndicatorView()
    private let errorImageView = UIImageView()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(errorImageView)
        stackView.addArrangedSubview(messageLabel)

        // Auto Layout
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])

        // 레이블 설정
        messageLabel.font = .preferredFont(forTextStyle: .caption1)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        // 에러 이미지 설정
        errorImageView.contentMode = .scaleAspectFit
        errorImageView.isHidden = true

        // 액티비티 인디케이터 설정
        activityIndicator.color = .systemBlue
    }

    func setState(_ state: State) {
        switch state {
        case .loading:
            print("   → 로딩 상태로 변경")
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            errorImageView.isHidden = true
            messageLabel.text = "AI가 사용자 맞춤 코스를 찾고 있어요.."

        case .failed:
            print("   → 실패 상태로 변경")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            errorImageView.isHidden = false
            errorImageView.image = UIImage(systemName: "exclamationmark.circle.fill")
            errorImageView.tintColor = .systemRed
            messageLabel.text = "불러오지 못했습니다"

        case .networkError:
            print("   → 네트워크 오류 상태로 변경")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            errorImageView.isHidden = false
            errorImageView.image = UIImage(systemName: "wifi.exclamationmark")
            errorImageView.tintColor = .systemOrange
            messageLabel.text = "네트워크 오류입니다"
        }
    }
}

