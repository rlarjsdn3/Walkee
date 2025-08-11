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
        titleLabel.text = viewModel.title
        valueLabel.attributedText = NSAttributedString(string: "1,000보")
            .font(.preferredFont(forTextStyle: .footnote), to: "보") // TODO: - 실제 값 할당하기
        symbolImageView.image = UIImage(systemName: viewModel.systemName)

        addLineChartsHostingController(with: viewModel, parent: parent)
    }

    private func addLineChartsHostingController(
        with viewModel: HealthInfoStackCellViewModel,
        parent: UIViewController?
    ) {
        Task {
            do {
                let hkDatas = try await viewModel.fetchStatisticsCollectionHKData(options: .cumulativeSum)

                let chartsData = Array(hkDatas.prefix(upTo: 7))
                let hostingVC = LineChartsHostingController(chartsData: chartsData)

                parent?.addChild(hostingVC, to: chartsContainerView)
                self.lineChartsHostingController = hostingVC
            } catch {
                // TODO: - 예외 처리 UI 코드 작성하기
                print("🔴 Failed to fetch HealthKit data: \(error)")
            }
        }
    }
}
