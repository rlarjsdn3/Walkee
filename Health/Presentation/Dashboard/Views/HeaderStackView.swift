//
//  HeaderStackView.swift
//  Health
//
//  Created by 김건우 on 8/8/25.
//

import UIKit

final class HeaderLabelView: UIView {

    var message: String? {
        didSet { updateMessageLabel() }
    }

    private let headerImageView = UIImageView()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        commonInit()
    }

    private func commonInit() {
        self.addSubviews(headerImageView, messageLabel)

        headerImageView.image = UIImage(systemName: "circle.fill")?
            .applyingSymbolConfiguration(.init(pointSize: 10))
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.tintColor = .buttonBackground
        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: topAnchor, constant: 17),
            headerImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            headerImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])

        messageLabel.font = .systemFont(ofSize: 17, weight: .medium)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: headerImageView.trailingAnchor, constant: 12),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }

    private func updateMessageLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        messageLabel.numberOfLines = 3
        messageLabel.attributedText = NSAttributedString(string: message ?? "")
            .applyingAttribute(.paragraphStyle, value: paragraphStyle)
    }
}


#Preview(traits: .fixedLayout(width: 375, height: 250)){
    let view = HeaderLabelView()
    view.message = "보행 속도는 일정 거리(예: 1초당 몇 미터)를 걷는 속도를 의미하며, 전반적인 이동 능력과 건강 상태를 반영하는 중요한 지표입니다."
    return view
}
