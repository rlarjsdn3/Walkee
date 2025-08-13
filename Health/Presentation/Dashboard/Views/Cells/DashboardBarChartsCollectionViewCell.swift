//
//  DashboardBarChartsCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import UIKit

final class DashboardBarChartsCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var averageTitleLabel: UILabel!
    @IBOutlet weak var averageValueLabel: UILabel!
    @IBOutlet weak var chartsContainerView: UIView!
    @IBOutlet weak var rangeOfDateLabel: UILabel!
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

        averageTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        rangeOfDateLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        barChartsView.configuration.displayOptions.showValueLabel = true

        registerForTraitChanges()
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            if self.traitCollection.userInterfaceStyle == .dark {
                self.chartsContainerView.layer.borderWidth = 0
            } else {
                self.chartsContainerView.layer.borderWidth = 1
            }
        }
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
    
    private func render(for state: LoadState<DashboardChartsContents>) {
        var attrString: NSAttributedString
        headerLabel.text = viewModel.headerTitle

        switch state {
        case .idle:
            return // TODO: - 플레이스 홀더 UI 구성하기
            
        case .loading:
            return // TODO: - 스켈레톤 UI 코드 구성하기
            
        case let .success(chartsDatas):
            let count = Double(chartsDatas.count)
            let avgValue = chartsDatas.reduce(0.0, { $0 + $1.value }) / count
            let avgString = avgValue.formatted(.number.precision(.fractionLength(0))) + " 걸음"
            attrString = NSAttributedString(string: avgString)

            barChartsView.chartData = prepareChartData(
                chartsDatas,
                type: viewModel.itemID.kind
            )
            if case .monthsBack = viewModel.itemID.kind {
                if traitCollection.horizontalSizeClass == .compact &&
                    traitCollection.verticalSizeClass == .regular {
                    barChartsView.configuration.barWidth = 12
                }
            }

            guard let startDate = chartsDatas.first?.date,
                  let endDate  = chartsDatas.last?.date
            else { return }
            rangeOfDateLabel.text = prepareRangeOfDateString(from: startDate, to: endDate)


        case .failure:
            // TODO: - 차트 중앙에 '데이터를 불러올 수 없다'고 표시
            attrString = NSAttributedString(string: "-")
            print("🔴 건강 데이터를 불러오는 데 실패함: DashboardBarChartsCell (\(viewModel.itemID.kind))")

        case .denied:
            // TODO: - 차트 중앙에 '접근 권한이 없다'고 표시
            attrString = NSAttributedString(string: "-")
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: DashboardBarChartsCell (\(viewModel.itemID.kind))")
        }

        averageValueLabel.attributedText = attrString
            .font(.preferredFont(forTextStyle: .footnote), to: "걸음")
            .foregroundColor(.secondaryLabel, to: "걸음")
    }


    private func prepareChartData(_ chartsDatas: DashboardChartsContents, type: BarChartsBackKind) -> BarChartsView.ChartData {
        let chartsElements = chartsDatas.map {
            if case .daysBack = type {
                return BarChartsView.ChartData.Element(
                    value: $0.value.truncateDecimalPoint,
                    xLabel: $0.date.formatted(using: .weekdayShorthand),
                    date: $0.date
                )
            } else {
                return BarChartsView.ChartData.Element(
                    value: $0.value.truncateDecimalPoint,
                    xLabel: $0.date.formatted(.dateTime.month(.defaultDigits)) + "월",
                    date: $0.date
                )
            }
        }
        return BarChartsView.ChartData(elements: chartsElements)
    }

    private func prepareRangeOfDateString(from startDate: Date, to endDate: Date) -> String {

        let isYearDiff = !startDate.isEqual([.year], with: endDate)
        let isMonthDiff = !startDate.isEqual([.month], with: endDate)

        // 서로 년도가 다른 경우
        // 년도는 동일 / 월만 다른 경우
        // 월까지 모두 같은 경우

        if case .daysBack = viewModel.itemID.kind {
            var fStartDate: String
            var fEndDate: String

            if isYearDiff {
                // 시작 날짜와 마지막 날짜의 년도가 다른 경우
                fStartDate = startDate.formatted(using: .yyyymd)
                fEndDate = endDate.formatted(using: .yyyymd)
            } else if !isYearDiff && isMonthDiff {
                // 시작 날짜와 마지막 날짜의 년도가 동일한데, 월(月)이 다른 경우
                fStartDate = startDate.formatted(using: .md)
                fEndDate = endDate.formatted(using: .md)
            } else {
                // 월(月)이 동일한 경우
                fStartDate = startDate.formatted(using: .md)
                fEndDate = endDate.formatted(using: .d)
            }

            return "\(fStartDate)~\(fEndDate)"
        } else {
            let fStartDate = startDate.formatted(using: .yyyym)
            let fEndDate = isYearDiff
            ? endDate.formatted(using: .yyyym) // 시작 날짜와 마지막 날짜의 년도가 다른 경우
            : endDate.formatted(using: .m) // 시작 날짜와 마지막 날짜의 년도가 동일한 경우 경우

            return "\(fStartDate)~\(fEndDate)"
        }
    }
}

fileprivate extension Double {

    var truncateDecimalPoint: Double {
        Double(Int(self))
    }
}
