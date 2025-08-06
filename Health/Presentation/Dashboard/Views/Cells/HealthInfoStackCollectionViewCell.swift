//
//  DailyAvtivitySummaryCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import UIKit

final class HealthInfoStackCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var symbolContainerView: UIView!
    @IBOutlet weak var symbolImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var chartsContainerView: UIView!

    override func layoutSubviews() {
        symbolContainerView.layer.cornerRadius = symbolContainerView.bounds.height / 2
    }

    override func setupAttribute() {
        self.applyCornerStyle(.medium)
        self.backgroundColor = .boxBg
        self.layer.borderColor = UIColor.separator.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.15
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.layer.shadowRadius = 10
        self.layer.borderWidth = (traitCollection.userInterfaceStyle == .dark) ? 0 : 1

        symbolContainerView.backgroundColor = .systemGray6

        valueLabel.minimumScaleFactor = 0.5
        valueLabel.adjustsFontSizeToFitWidth = true

        chartsContainerView.isHidden = (traitCollection.horizontalSizeClass == .compact)

        registerForTraitChanges()
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            if self.traitCollection.userInterfaceStyle == .dark {
                self.layer.borderWidth = 0
            } else {
                self.layer.borderWidth = 1
            }
        }
    }
}

extension HealthInfoStackCollectionViewCell {

    func configure(with viewModel: HealthInfoStackCellViewModel) {
        symbolImageView.image = UIImage(systemName: viewModel.systemName)

    }
}
