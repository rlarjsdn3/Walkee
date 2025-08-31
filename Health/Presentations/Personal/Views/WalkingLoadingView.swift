//
//  WalkingLoadingView.swift
//  Health
//
//  Created by juks86 on 8/20/25.
//

import UIKit

/// AI 추천 코스 로딩 상태를 표시하는 커스텀 뷰
///
/// 이 뷰는 AI가 사용자 맞춤 걷기 코스를 추천하는 동안의 로딩, 실패, 네트워크 오류 상태에 따라
/// 시각적으로 표현합니다.
class WalkingLoadingView: UIView {

    /// 로딩 뷰의 현재 상태를 나타내는 열거형
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

    /// 로딩 뷰의 UI 요소들을 초기 설정합니다.
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
        messageLabel.font = .preferredFont(forTextStyle: .headline)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        // 에러 이미지 설정
        errorImageView.contentMode = .scaleAspectFit
        errorImageView.isHidden = true

        // 액티비티 인디케이터 설정
        activityIndicator.color = .systemBlue
    }

    /// 로딩 뷰의 상태를 변경하고 해당 상태에 맞는 UI를 표시합니다.
    ///
    /// - Parameter state: 설정할 새로운 상태
    func setState(_ state: State) {
        switch state {
        case .loading:
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            errorImageView.isHidden = true
            messageLabel.text = "AI가 사용자 맞춤 코스를 찾고 있어요.."

        case .failed:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            errorImageView.isHidden = true

            let warningIcon = UIImage(systemName: "exclamationmark.circle.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)

            let attachment = NSTextAttachment()
            attachment.image = warningIcon
            attachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)

            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(attachment: attachment))
            attributedString.append(NSAttributedString(string: " 추천 코스를 불러오지 못했습니다.\n쉬운 코스를 기본으로 보여드릴게요."))

            messageLabel.attributedText = attributedString

        case .networkError:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            errorImageView.isHidden = true
            let warningIcon = UIImage(systemName: "wifi.exclamationmark")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)

            let attachment = NSTextAttachment()
            attachment.image = warningIcon
            attachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)

            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(attachment: attachment))
            attributedString.append(NSAttributedString(string: " 네트워크 요청 시간이 초과되었습니다.\n쉬운 코스를 기본으로 보여드릴게요."))

            messageLabel.attributedText = attributedString
        }
    }
}

