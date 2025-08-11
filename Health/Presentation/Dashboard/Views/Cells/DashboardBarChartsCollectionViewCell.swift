//
//  DashboardBarChartsCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import UIKit

final class DashboardBarChartsCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var headerLabelView: UILabel!
    @IBOutlet weak var averageValueLabel: UILabel!
    @IBOutlet weak var chartsContainerView: UIView!
    @IBOutlet weak var barChartsView: BarChartsView!

    private var viewModel: DashboardBarChartsCellViewModel!

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

        Task {
            do {
                let hkDatas = try await viewModel.fetchStatisticsCollectionHKDatas(options: .cumulativeSum)
                let avgData = try await viewModel.fetchStatisticsCollectionHKDatas(options: .discreteAverage)

                // TODO: - 코드 리팩토링하기
                barChartsView.chartData = prepareChartData(hkDatas, type: viewModel.backType)
                if case .daysBack = viewModel.backType {
                    
                } else {
                    if traitCollection.horizontalSizeClass == .compact &&
                        traitCollection.verticalSizeClass == .regular {
                        barChartsView.configuration.barWidth = 12
                    }
                }

                // TODO: - 평균값 포매팅 및 글자 폰트 다시 처리하기

                headerLabelView.text = viewModel.headerTitle
                averageValueLabel.text = (avgData.first?.value.formatted() ?? "0") + "보"
            } catch {
                // TODO: - 예외 UI 출력하기
                print("🔴 Failed to fetch HealthKit Datas: \(error)")
            }
        }
    }

    private func prepareChartData(_ hkDatas: [HealthKitData], type: BarChartsBackType) -> BarChartsView.ChartData {
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
        return BarChartsView.ChartData(elements: reversedChartsElements) // TODO: - 목표 걸음수 Limit 값 넣기
    }
}
