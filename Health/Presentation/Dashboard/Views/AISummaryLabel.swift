//
//  AISummaryLabel.swift
//  Health
//
//  Created by 김건우 on 8/19/25.
//

import UIKit

final class AISummaryLabel: CoreView {

    private let icon = UIImageView()
    private let label = UILabel()

    private let iconSize: CGFloat = 20
    private let labelLeading: CGFloat = 12

    ///
    var text: String? {
        didSet { label.text = text }
    }

    override var intrinsicContentSize: CGSize {
        getCGSize(label.text)
    }

    override func setupHierarchy() {
        addSubviews(icon, label)
    }

    override func setupAttribute() {
        icon.image = UIImage(resource: .chatBot)
        icon.translatesAutoresizingMaskIntoConstraints = false

        label.text = "Hello, World!"
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor),
            icon.topAnchor.constraint(equalTo: topAnchor),
            icon.widthAnchor.constraint(equalToConstant: iconSize),
            icon.heightAnchor.constraint(equalToConstant: iconSize),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: labelLeading),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

extension AISummaryLabel {

    func getCGSize(_ text: String?) -> CGSize {
        guard self.bounds.width > 0 else {
            return CGSizeMake(UIView.noIntrinsicMetric, UIView.noIntrinsicMetric)
        }

        let text = (label.attributedText?.string as NSString?) ??
                   (label.text as NSString? ?? "")
        let font = label.font ?? UIFont.preferredFont(forTextStyle: .callout)
        let width = max(0, self.bounds.width
                        - iconSize       // 왼쪽 아이콘의 너비
                        - labelLeading)  // 스택의 간격(spacing)

        let rect = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesFontLeading, .usesLineFragmentOrigin],
            attributes: [.font: font],
            context: nil
        )

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: ceil(rect.height)
        )
    }
}
