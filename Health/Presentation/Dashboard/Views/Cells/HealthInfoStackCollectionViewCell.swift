//
//  DailyAvtivitySummaryCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import HealthKit
import UIKit
import SwiftUI

final class HealthInfoStackCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var symbolContainerView: UIView!
    @IBOutlet weak var symbolImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var chartsContainerView: UIView!

    private var lineChartsHostingController: UIHostingController<LineChartsView>?

    override func layoutSubviews() {
        symbolContainerView.layer.cornerRadius = symbolContainerView.bounds.height / 2
    }

    override func prepareForReuse() {
        lineChartsHostingController = nil
        chartsContainerView.subviews.forEach { $0.removeFromSuperview() }
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

        chartsContainerView.backgroundColor = .boxBg
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

    func configure(with viewModel: HealthInfoStackCellViewModel, parent: UIViewController?) {
        titleLabel.text = viewModel.title
        valueLabel.attributedText = NSAttributedString(string: "1,000보")
            .font(.preferredFont(forTextStyle: .footnote), to: "보") // TODO: - 실제 값 할당하기
        symbolImageView.image = UIImage(systemName: viewModel.systemName)

        addLineChartsHostingController(with: viewModel, parent: parent)
    }

    private func addLineChartsHostingController(with viewModel: HealthInfoStackCellViewModel, parent: UIViewController?) {
        Task {
            do {
                let hkDatas = try await viewModel.fetchStatisticsCollectionData(
                    from: .now.addingTimeInterval(-7 * 86_400).startOfDay(),
                    to: .now.endOfDay(),
                    options: .cumulativeSum
                ).prefix(through: 7)

                let chartsData = Array(hkDatas)
                let hostingVC = LineChartsHostingController(chartsData: chartsData)

                parent?.addChild(hostingVC, to: chartsContainerView)
                self.lineChartsHostingController = hostingVC

            } catch {
                print("❌ Failed to fetch HealthKit data: \(error)")
            }
        }
    }
}
