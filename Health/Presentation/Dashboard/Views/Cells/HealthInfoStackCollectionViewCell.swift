//
//  DailyAvtivitySummaryCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import HealthKit
import UIKit
import SwiftUI

final class HealthInfoStackCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var symbolContainerView: UIView!
    @IBOutlet weak var symbolImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var chartsContainerView: UIView!

    private var chartsHostingController: UIHostingController<LineChartsView>?

    private var viewModel: HealthInfoStackCellViewModel!
    private var cancellable: Set<AnyCancellable> = []

    override func layoutSubviews() {
//       symbolContainerView.applyCornerStyle(.circular)
        symbolContainerView.layer.cornerRadius = symbolContainerView.bounds.height / 2
    }

    override func prepareForReuse() {
        chartsHostingController = nil
        chartsContainerView.subviews.forEach { $0.removeFromSuperview() }
        cancellable.removeAll()
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

        symbolContainerView.backgroundColor = .systemGray5

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
        self.viewModel = viewModel

        viewModel.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state, parent: parent) }
            .store(in: &cancellable)
    }

    private func render(_ new: LoadState<InfoStackContent>, parent: UIViewController?) {
        var lblString: String
        let unitString = viewModel.itemID.kind.unitString
        titleLabel.text = viewModel.itemID.kind.title
        symbolImageView.image = UIImage(systemName: viewModel.itemID.kind.systemName)
        unitLabel.text = unitString

        switch new {
        case .idle:
            return // TODO: - 로딩 전 플레이스 홀더 UI 구성하기
            
        case .loading:
            return // TODO: - 로딩 시 Skeleton Effect 출력하기

        case let .success(content):
            lblString = String(format: "%0.f", content.value)

            if let charts = content.charts, !charts.isEmpty {
                if traitCollection.verticalSizeClass == .regular &&
                    traitCollection.horizontalSizeClass == .regular {
                    addChartsHostingController(with: charts, parent: parent)
                }
            }

        case .failure:
            lblString = "0"
            print("🔴 건강 데이터를 불러오는 데 실패함: HealthInfoStackCell (\(viewModel.itemID.kind.quantityTypeIdentifier))")

        case .denied:
            lblString = "-"
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: HealthInfoStackCell (\(viewModel.itemID.kind.quantityTypeIdentifier))")
        }

        valueLabel.text = lblString
    }

    private func addChartsHostingController(
        with charts: [InfoStackContent.Charts],
        parent: UIViewController?
    ) {
        // TOOD: - LineCharts가 범용 데이터를 받도록 코드 리팩토링하기
        let sliced = Array(charts.prefix(7))
        let hkd = sliced.map { HKData(startDate: $0.date, endDate: $0.date, value: $0.value) }
        let hVC = LineChartsHostingController(chartsData: hkd)
        parent?.addChild(hVC, to: chartsContainerView)
        self.chartsHostingController = hVC
    }
}
