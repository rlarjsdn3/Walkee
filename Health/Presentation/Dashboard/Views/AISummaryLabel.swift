//
//  AISummaryLabel.swift
//  Health
//
//  Created by 김건우 on 8/19/25.
//

import UIKit

final class AISummaryLabel: CoreView {

    private let imageView = UIImageView()
    private let summaryLabel = UILabel()
    private let containerStackView = UIStackView()

    /// 요약 텍스트를 표시하거나 가져옵니다.
    var text: String? {
        get { summaryLabel.text }
        set { summaryLabel.text = newValue }
    }

    override var intrinsicContentSize: CGSize {
        guard self.bounds.width > 0 else {
            return CGSizeMake(UIView.noIntrinsicMetric, UIView.noIntrinsicMetric)
        }

        let text = (summaryLabel.attributedText?.string as NSString?) ??
                   (summaryLabel.text as NSString? ?? "")
        let font = summaryLabel.font ?? UIFont.preferredFont(forTextStyle: .callout)
        let width = max(0, self.bounds.width
                        - 26   // 왼쪽 아이콘의 너비
                        - 12)  // 스택의 간격(spacing)

        let rect = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesFontLeading, .usesLineFragmentOrigin],
            attributes: [.font: font],
            context: nil
        )

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: ceil(rect.height) + 2 // top 패딩 합
        )
    }

    override func setupHierarchy() {
        addSubview(containerStackView)
        containerStackView.addArrangedSubviews(imageView, summaryLabel)
    }

    override func setupAttribute() {
        containerStackView.spacing = 12
        containerStackView.alignment = .top
        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        imageView.image = UIImage(resource: .chatBot)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        summaryLabel.text = "Hello, World!"
        summaryLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        summaryLabel.textColor = .label
        summaryLabel.numberOfLines = 0
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0)
        ])

        NSLayoutConstraint.activate([
            summaryLabel.topAnchor.constraint(equalTo: containerStackView.topAnchor, constant: 2)
        ])
    }
}
