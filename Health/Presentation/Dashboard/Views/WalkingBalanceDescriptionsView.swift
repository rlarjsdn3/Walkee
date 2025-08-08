//
//  WalkingBalanceDescriptionsView.swift
//  Health
//
//  Created by 김건우 on 8/8/25.
//

import UIKit

final class WalkingBalanceDescriptionsView: UIView {

    private let descriptionsStackView = UIStackView()

    var descriptions: [String]? = nil {
        didSet { self.setNeedsLayout() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        addSubview(descriptionsStackView)
        descriptionsStackView.axis = .vertical
        descriptionsStackView.alignment = .fill
        descriptionsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descriptionsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionsStackView.topAnchor.constraint(equalTo: topAnchor),
            descriptionsStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            descriptionsStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    override func layoutSubviews() {
        descriptionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        descriptionsStackView.subviews.forEach { $0.removeFromSuperview() }

        descriptions?.forEach { description in
            let headerLabel = HeaderLabelView()
            headerLabel.desc = description
            descriptionsStackView.addArrangedSubview(headerLabel)
        }
    }

}
