//
//  BarChartView.swift
//  BarChartViewProject
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

final class BarChartsView: UIView {

    /// 차트에 표시할 데이터입니다.
    ///
    /// 설정 시 내부 레이아웃이 갱신되어, 새로운 데이터에 맞게 막대가 다시 그려집니다.
    var chartData: BarChartsView.ChartData? {
        didSet { self.setNeedsLayout() }
    }

    /// 차트의 스타일 및 표시 옵션을 정의하는 설정 값입니다.
    ///
    /// 기본값은 `.default()`이며, 설정이 변경되면 뷰가 다시 레이아웃됩니다.
    var configuration: BarChartsView.Configuration = .default() {
        didSet { self.setNeedsLayout() }
    }

    private var elementViews: [UIView] = []
    private var barChartsStackView = UIStackView()
    private var graphInConstruction = false
    private var previousMonthValue: Int? = nil

    /// 지정된 데이터와 설정으로 막대 차트 뷰를 초기화합니다.
    ///
    /// - Parameters:
    ///   - chartData: 차트에 표시할 데이터
    ///   - configuration: 차트의 외형 및 표시 설정 (기본값은 `.default()`)
    init(
        chartData: BarChartsView.ChartData,
        configuration: BarChartsView.Configuration = .default()
    ) {
        self.chartData = chartData
        self.configuration = configuration
        super.init(frame: .zero)

        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        barChartsStackView.distribution = .equalCentering
        barChartsStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(barChartsStackView)
        NSLayoutConstraint.activate([
            barChartsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            barChartsStackView.topAnchor.constraint(equalTo: topAnchor),
            barChartsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            barChartsStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        guard let chartData = chartData else { return }
        constructGraph(using: chartData)
    }

    private func constructGraph(using chartData: ChartData) {
        guard !graphInConstruction else { return }
        graphInConstruction = true
        defer {
            graphInConstruction = false
        }

        previousMonthValue = nil
        barChartsStackView.subviews.forEach { $0.removeFromSuperview() }
        barChartsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        elementViews.removeAll()

        var values = chartData.elements.map { $0.value }
        if let limitValue = chartData.limit?.value {
            values.append(limitValue)
        }

        let maxValue = values.max() ?? 0

        chartData.elements.forEach { element in
            let elementView = UIView()
            barChartsStackView.addArrangedSubview(elementView)
            elementView.translatesAutoresizingMaskIntoConstraints = false
            elementView.widthAnchor.constraint(greaterThanOrEqualToConstant: configuration.barWidth).isActive = true

            let xAxisLabel = UILabel()
            add(
                xAxisLabel: xAxisLabel,
                elementView: elementView,
                element: element
            )

            let barParentView = UIView()
            add(
                parentView: barParentView,
                elementView: elementView,
                xAxisLabel: xAxisLabel
            )

            let barView = UIView()
            add(
                barView: barView,
                parentView: barParentView,
                element: element,
                maxValue: maxValue
            )

            if configuration.displayOptions.showValueLabel {
                let valueLabel = UILabel()
                add(
                    valueLabel: valueLabel,
                    parentView: barParentView,
                    barView: barView,
                    element: element
                )
            }

            elementViews.append(elementView)
        }

        // 기준선(limit) 데이터가 존재하고,
        // 첫 번째 막대 요소 뷰 내부에서 barParentView를 안전하게 가져올 수 있는 경우에만
        // 기준선을 그립니다.
        if let limit = chartData.limit,
           let barParentView = elementViews.first?.subviews[safe: 1] {
            drawLimitLine(parentView: barParentView, limit: limit, maxValue: maxValue)
        }
    }

    private func add(
        xAxisLabel: UILabel,
        elementView: UIView,
        element: ChartData.Element
    ) {
        let elementDate = element.date

        // 데이터에 사용자 지정 x축 레이블(xLabel)이 있는 경우 해당 값을 그대로 표시합니다.
        if let xLabel = element.xLabel {
            xAxisLabel.text = xLabel
        } else {
            // 사용자 지정 레이블이 없을 경우, 날짜를 기반으로 레이블을 구성합니다.
            if let prevMonthValue = previousMonthValue {
                // 이전 요소의 월과 현재 요소의 월이 다르면 "M.d" 형식으로 월+일을 표시합니다.
                // (월이 바뀌는 지점에만 월 정보를 노출하여 가독성 향상)
                if prevMonthValue != elementDate.month {
                    xAxisLabel.text = elementDate.formatted(using: .m_d)
                } else {
                    // 같은 월이라면 날짜(일)만 표시합니다.
                    xAxisLabel.text = elementDate.formatted(.dateTime.day())
                }
            } else {
                // 처음 추가되는 레이블이라면 "M.d" 형식으로 표시합니다.
                xAxisLabel.text = elementDate.formatted(using: .m_d)
            }
        }
        // 현재 요소의 월 정보를 저장해 다음 비교에 사용합니다.
        previousMonthValue = elementDate.month

        xAxisLabel.font = configuration.textStyle.xAxisLabelFont
        xAxisLabel.textColor = configuration.textStyle.xAxisLabelTint
        xAxisLabel.textAlignment = .center
        xAxisLabel.translatesAutoresizingMaskIntoConstraints = false

        elementView.addSubview(xAxisLabel)
        NSLayoutConstraint.activate([
            xAxisLabel.bottomAnchor.constraint(equalTo: elementView.bottomAnchor),
            xAxisLabel.leadingAnchor.constraint(equalTo: elementView.leadingAnchor),
            xAxisLabel.trailingAnchor.constraint(equalTo: elementView.trailingAnchor)
        ])
    }

    private func add(
        parentView barParentView: UIView,
        elementView: UIView,
        xAxisLabel: UILabel
    ) {
        elementView.addSubview(barParentView)

        barParentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            barParentView.bottomAnchor.constraint(equalTo: xAxisLabel.topAnchor, constant: -6),
            barParentView.widthAnchor.constraint(equalToConstant: configuration.barWidth),
            barParentView.heightAnchor.constraint(equalToConstant: self.bounds.height * 0.75),
            barParentView.centerXAnchor.constraint(equalTo: elementView.centerXAnchor)
        ])

    }

    private func add(
        barView: UIView,
        parentView barParentView: UIView,
        element: ChartData.Element,
        maxValue: Double
    ) {
        barParentView.layoutIfNeeded()
        barParentView.setNeedsLayout()

        barView.backgroundColor = .systemTeal
        barView.layer.cornerRadius = configuration.barWidth / 3
        barView.translatesAutoresizingMaskIntoConstraints = false

        barParentView.addSubview(barView)
        NSLayoutConstraint.activate([
            barView.leadingAnchor.constraint(equalTo: barParentView.leadingAnchor),
            barView.bottomAnchor.constraint(equalTo: barParentView.bottomAnchor),
            barView.trailingAnchor.constraint(equalTo: barParentView.trailingAnchor)
        ])

        // 최대값에 비해 현재 값이 어느 정도인지 계산한 비율(역수)입니다.
        // 예: 최대값이 10,000이고 현재 값이 5,000이면, 비율은 2입니다.
        // 이 값은 막대가 전체 높이 중 얼마만큼 차지할지를 계산하는 데 사용됩니다.
        let divider = CGFloat(maxValue / element.value)

        // 막대의 실제 높이를 계산합니다.
        // 전체 높이에서 위에서 구한 비율만큼 나누어, 현재 값에 비례한 높이를 구합니다.
        let barHeight = barParentView.frame.height * (1 / divider)

        // 계산된 높이가 너무 작을 경우에는 막대의 너비만큼은 최소한 높이를 보장해줍니다.
        if barHeight < configuration.barWidth {
            barView.heightAnchor.constraint(equalToConstant: configuration.barWidth).isActive = true
        } else {
            barView.heightAnchor.constraint(equalToConstant: barHeight).isActive = true
        }
    }

    private func add(
        valueLabel: UILabel,
        parentView barParentView: UIView,
        barView: UIView,
        element: ChartData.Element
    ) {
        valueLabel.text = element.value.formatted()
        valueLabel.textColor = configuration.textStyle.valueLabelTint
        valueLabel.font = configuration.textStyle.valueLabelFont
        valueLabel.layer.zPosition = 999
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        barParentView.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            valueLabel.bottomAnchor.constraint(equalTo: barView.topAnchor, constant: -2),
            valueLabel.centerXAnchor.constraint(equalTo: barView.centerXAnchor)
        ])
    }

    func drawLimitLine(
        parentView barParentView: UIView,
        limit: ChartData.Limit,
        maxValue: Double
    ) {
        barParentView.layoutIfNeeded()
        barParentView.setNeedsLayout()

        // 최대값 기준으로 1 단위당 몇 pt인지 계산합니다.
        // 예: barParentView 높이가 200이고 최대값이 10,000이면, 1 단위당 0.02pt입니다.
        let point = CGFloat(barParentView.frame.height / maxValue)

        // limit 값이 시각적으로 어느 위치에 표시되어야 하는지 계산합니다.
        // 예: limit.value = 5000이면, bottom에서부터 5000 × 0.02 = 100pt 위에 표시해야 합니다.
        var bottomPadding = CGFloat(limit.value * point)

        // limit 라인이 너무 아래에 그려지지 않도록 최소 여백(=막대 너비)만큼 보정합니다.
        if bottomPadding < configuration.barWidth {
            bottomPadding = configuration.barWidth
        }

        let limitView = LimitView()
        limitView.text = limit.label
        limitView.configuration = configuration
        limitView.translatesAutoresizingMaskIntoConstraints = false

        barChartsStackView.addSubview(limitView) // x-xcode-debug-views:///36d7d7560 Height and vertical position are ambiguous for LimitView.

        NSLayoutConstraint.activate([
            limitView.bottomAnchor.constraint(equalTo: barParentView.bottomAnchor, constant: -bottomPadding),
            limitView.leadingAnchor.constraint(equalTo: barChartsStackView.leadingAnchor),
            limitView.trailingAnchor.constraint(equalTo: barChartsStackView.trailingAnchor)
        ])
    }
}
