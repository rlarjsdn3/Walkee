//
//  HealthInfoCardCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import UIKit

final class HealthInfoCardCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var symbolImage: UIImageView!
    @IBOutlet weak var symbolContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func layoutSubviews() {
//        symbolContainerView.applyCornerStyle(.circular)
        symbolContainerView.layer.cornerRadius = symbolContainerView.bounds.height / 2
    }

    override func setupAttribute() {
//       self.applyCornerStyle(.medium)
        self.backgroundColor = .boxBg
        self.layer.cornerRadius = 12 // medium
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.separator.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.05
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 5
        self.layer.borderWidth = (traitCollection.userInterfaceStyle == .dark) ? 0 : 1

        symbolContainerView.backgroundColor = .systemGray6

        valueLabel.minimumScaleFactor = 0.5
        valueLabel.adjustsFontSizeToFitWidth = true

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

extension HealthInfoCardCollectionViewCell {

    func configure(with viewModel: HealthInfoCardCellViewModel) {

        Task {
            do {
                let hkData = try await viewModel.fetchStatisticsHealthKitData(options: .mostRecent)
                let status = viewModel.evaluateStatus(hkData.value)

                let systemImage = UIImage(systemName: status.systemName)?
                    .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.white]))?
                    .applyingSymbolConfiguration(UIImage.SymbolConfiguration(weight: .semibold))
                symbolImage.image = systemImage
                symbolContainerView.backgroundColor = status.backgroundColor
                titleLabel.text = viewModel.cardType.title
                valueLabel.attributedText = NSAttributedString(string: "1,000보")
                    .font(.preferredFont(forTextStyle: .footnote), to: "보")
            } catch {
                // TODO: - UI 예외 처리하기
                print("Failed to fetch HealthKit data: \(error)")
                return
            }
        }
    }
}
