//
//  HealthInfoCardCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import UIKit

final class HealthInfoCardCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var statusContainerView: UIView!
    @IBOutlet weak var gaitStatusLabel: UILabel!
    @IBOutlet weak var statusProgressBarView: StatusProgressBarView!

    override func layoutSubviews() {
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

        statusContainerView.applyCornerStyle(.small)

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

    func bind(with viewModel: HealthInfoCardCellViewModel) {

        Task {
            do {
                titleLabel.text = viewModel.cardType.title
                statusProgressBarView.higherIsBetter = viewModel.cardType.higerIsBetter
                statusProgressBarView.thresholdsValues = viewModel.cardType.thresholdValues(age: viewModel.age)

                let hkData = try await viewModel.fetchStatisticsHealthKitData(options: .mostRecent)
                let status = viewModel.evaluateGaitStatus(hkData.value)

                let unitString = viewModel.cardType.unitString
                let formattedValue = switch viewModel.cardType {
                case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage: hkData.value * 100.0
                case .walkingSpeed, .walkingStepLength: hkData.value
                }

                statusProgressBarView.currentValue = hkData.value
                statusProgressBarView.numberFormatter = prepareNumberFormatter(type: viewModel.cardType)
                valueLabel.attributedText = NSAttributedString(string: String(format: "%.1f", formattedValue) + unitString)
                    .font(.preferredFont(forTextStyle: .footnote), to: unitString)
                    .foregroundColor(.secondaryLabel, to: unitString)

                gaitStatusLabel.text = status.rawValue
                gaitStatusLabel.textColor = status.backgroundColor
                statusContainerView.backgroundColor = status.secondaryBackgroundColor

            } catch {
                let unitString = viewModel.cardType.unitString
                valueLabel.attributedText = NSAttributedString(string: "- " + unitString)
                    .font(.preferredFont(forTextStyle: .footnote), to: unitString)
                    .foregroundColor(.secondaryLabel, to: unitString)
                statusContainerView.isHidden = true
                statusProgressBarView.currentValue = nil

                print("🔴 Failed to fetch HealthKit data: \(error)")
            }
        }
    }

    private func prepareNumberFormatter(type: DashboardCardType) -> NumberFormatter? {
        switch type {
        case .walkingDoubleSupportPercentage, .walkingAsymmetryPercentage:
            let nf = NumberFormatter()
            nf.numberStyle = .percent
            return nf
        case .walkingStepLength, .walkingSpeed:
            return nil
        }
    }
}
