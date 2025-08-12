//
//  DashboardBarChartsCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import UIKit

final class DashboardBarChartsCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var headerLabelView: UILabel!
    @IBOutlet weak var averageValueLabel: UILabel!
    @IBOutlet weak var chartsContainerView: UIView!
    @IBOutlet weak var barChartsView: BarChartsView!

    private var viewModel: DashboardBarChartsCellViewModel!
    
    private var cancellable: Set<AnyCancellable> = []

    override func setupAttribute() {
//       self.applyCornerStyle(.medium)
        chartsContainerView.backgroundColor = .boxBg
        chartsContainerView.layer.cornerRadius = 12 // medium
        chartsContainerView.layer.masksToBounds = false
        chartsContainerView.layer.borderColor = UIColor.separator.cgColor
        chartsContainerView.layer.shadowColor = UIColor.black.cgColor
        chartsContainerView.layer.shadowOpacity = 0.05
        chartsContainerView.layer.shadowOffset = CGSize(width: 2, height: 2)
        chartsContainerView.layer.shadowRadius = 5
        chartsContainerView.layer.borderWidth = (traitCollection.userInterfaceStyle == .dark) ? 0 : 1
    }
}

extension DashboardBarChartsCollectionViewCell {

    func bind(with viewModel: DashboardBarChartsCellViewModel) {
        self.viewModel = viewModel

        viewModel.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(for: state) }
            .store(in: &cancellable)
    
    }
    
    private func render(for state: HKLoadState) {
        headerLabelView.text = viewModel.headerTitle
        
        switch state {
        case .idle:
            return // TODO: - 플레이스 홀더 UI 구성하기
            
        case .loading:
            return // TODO: - 스켈레톤 UI 코드 구성하기
            
        case let .success(_, collection):
            guard let collection = collection else { return }
            
            let avgValue = collection.reduce(0, { $0 + Int($1.value) }) / collection.count
            
            barChartsView.chartData = prepareChartData(
                collection,
                type: viewModel.itemID.kind
            )

            if case .monthsBack = viewModel.itemID.kind {
                if traitCollection.horizontalSizeClass == .compact &&
                    traitCollection.verticalSizeClass == .regular {
                    barChartsView.configuration.barWidth = 12
                }
            }
            
            averageValueLabel.text = avgValue.formatted() + "걸음"
            
            
            return //
            
        case .failure:
            // TODO: - 예외 UI 로직 구현하기
            
            print("🔴 Failed to fetch HealthKit Datas: DashboardBarChartsCell (\(viewModel.itemID.kind))")
        }
    }


    private func prepareChartData(_ hkDatas: [HKData], type: BarChartsBackKind) -> BarChartsView.ChartData {
        let chartsElements = hkDatas.map {
            if case .daysBack = type {
                return BarChartsView.ChartData.Element(
                    value: $0.value,
                    xLabel: $0.startDate.formatted(using: .weekdayShorthand),
                    date: $0.startDate
                )
            } else {
                return BarChartsView.ChartData.Element(
                    value: $0.value,
                    xLabel: $0.startDate.formatted(.dateTime.month(.defaultDigits)) + "월",
                    date: $0.startDate
                )
            }
        }
        let reversedChartsElements = Array(chartsElements.reversed())
        return BarChartsView.ChartData(elements: reversedChartsElements)
    }
}
