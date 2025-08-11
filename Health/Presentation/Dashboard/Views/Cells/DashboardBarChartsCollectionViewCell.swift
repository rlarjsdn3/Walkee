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
                let hkDatas = try await viewModel.fetchStatisticsCollectionHKData()
                let avgData = try await viewModel.fetchStatisticsCollectionHKData(options: .discreteAverage)

                if case .daysBack = viewModel.backType {
                    if traitCollection.horizontalSizeClass == .compact &&
                        traitCollection.verticalSizeClass == .regular {
                        barChartsView.chartData = prepareChartData(hkDatas, upTo: 7)
                    } else {
                        barChartsView.chartData = prepareChartData(hkDatas, upTo: 14)
                    }
                } else {
                    barChartsView.chartData = prepareChartData(hkDatas, upTo: 12)
                }

                // TODO: - 평균값 포매팅 및 글자 폰트 다시 처리하기

                headerLabelView.text = viewModel.headerTitle
                averageValueLabel.text = avgData.first?.value.formatted() ?? "0" + "보"
            } catch {
                // TODO: - 예외 UI 출력하기
                print("🔴 Failed to fetch HealthKit Datas: \(error)")
                return
            }
        }
    }

    private func prepareChartData(_ hkDatas: [HealthKitData], upTo count: Int) -> BarChartsView.ChartData {
        let prefixedDatas: [HealthKitData] = Array(hkDatas.prefix(upTo: count))
        let chartsElements = prefixedDatas.map { BarChartsView.ChartData.Element(value: $0.value, date: $0.startDate) }
        let reversedChartsElements = Array(chartsElements.reversed())
        return BarChartsView.ChartData(elements: reversedChartsElements) // TODO: - 목표 걸음수 Limit 값 넣기
    }
}
