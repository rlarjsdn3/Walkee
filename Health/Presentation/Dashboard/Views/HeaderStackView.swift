//
//  HeaderStackView.swift
//  Health
//
//  Created by 김건우 on 8/8/25.
//

import UIKit

final class HeaderLabelView: UIView {

    var desc: String? {
        didSet { updateDescriptionLabel() }
    }

    private let headerImageView = UIImageView()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        commonInit()
    }

    private func commonInit() {
        self.addSubviews(headerImageView, descriptionLabel)

        headerImageView.image = UIImage(systemName: "circle.fill")?
            .applyingSymbolConfiguration(.init(pointSize: 10))
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.tintColor = .buttonBackground
        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: topAnchor, constant: 17),
            headerImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            headerImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])

        descriptionLabel.font = .systemFont(ofSize: 17, weight: .medium)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: headerImageView.trailingAnchor, constant: 12),
            descriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }

    private func updateDescriptionLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        descriptionLabel.numberOfLines = 3
        descriptionLabel.attributedText = NSAttributedString(string: desc ?? "")
            .applyingAttribute(.paragraphStyle, value: paragraphStyle)
    }
}
