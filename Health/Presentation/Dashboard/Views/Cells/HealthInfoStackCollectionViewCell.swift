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
//       symbolContainerView.applyCornerStyle(.circular)
        symbolContainerView.layer.cornerRadius = symbolContainerView.bounds.height / 2
    }

    override func prepareForReuse() {
        lineChartsHostingController = nil
        chartsContainerView.subviews.forEach { $0.removeFromSuperview() }
    }

    override func setupAttribute() {
//        self.applyCornerStyle(.medium)
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

    func bind(
        with viewModel: HealthInfoStackCellViewModel,
        parent: UIViewController?
    ) {
        Task { // TODO: - 아이패드에서 차트 UI가 제대로 예외처리되는지 확인하기
            do {
                titleLabel.text = viewModel.stackType.title
                symbolImageView.image = UIImage(systemName: viewModel.stackType.systemName)

                let hkData = try await viewModel.fetchStatisticsHKData()
                let chartsDatas = try await viewModel.fetchStatisticsCollectionHKData(options: .cumulativeSum)

                let unitString = viewModel.stackType.unitString
                valueLabel.attributedText = NSAttributedString(string: String(format: "%.1f", hkData.value) + unitString)
                    .font(.preferredFont(forTextStyle: .footnote), to: unitString)
                    .foregroundColor(.secondaryLabel, to: unitString)

                addLineChartsHostingController(with: chartsDatas, parent: parent)
            } catch {
                let unitString = viewModel.stackType.unitString
                valueLabel.attributedText = NSAttributedString(string: "- " + unitString)
                    .font(.preferredFont(forTextStyle: .footnote), to: unitString)
                    .foregroundColor(.secondaryLabel, to: unitString)

                print("🔴 Failed to fetch HealthKit data: \(error) (HealthInfoStackCell)")
            }
        }
    }

    private func addLineChartsHostingController(
        with chartsData: [HealthKitData],
        parent: UIViewController?
    ) {
        let hostingVC = LineChartsHostingController(chartsData: chartsData)
        parent?.addChild(hostingVC, to: chartsContainerView)
        self.lineChartsHostingController = hostingVC
    }
}
