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

    func configure(with viewModel: HealthInfoCardCellViewModel) {

        Task {
            do {
                let hkData = try await viewModel.fetchStatisticsHealthKitData(options: .mostRecent)
                let status = viewModel.evaluateStatus(hkData.value)

                titleLabel.text = viewModel.cardType.title
                valueLabel.attributedText = NSAttributedString(string: "1,000보") // TODO: - 실제 데이터 가져오기
                    .font(.preferredFont(forTextStyle: .footnote), to: "보")
                    .foregroundColor(.secondaryLabel, to: "보")

                gaitStatusLabel.text = status.rawValue
                gaitStatusLabel.textColor = status.backgroundColor
                statusContainerView.backgroundColor = status.secondaryBackgroundColor

                statusProgressBarView.currentValue = hkData.value
                statusProgressBarView.thresholdsValues = viewModel.cardType.thresholdValues(age: 27) // TODO: - 나이 데이터 가져오기
                statusProgressBarView.higherIsBetter = viewModel.cardType.higerIsBetter
            } catch {
                // TODO: - UI 예외 처리하기
                print("Failed to fetch HealthKit data: \(error)")
                return
            }
        }
    }
}
