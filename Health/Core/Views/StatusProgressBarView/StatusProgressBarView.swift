//
//  StatusProgressBarView.swift
//  Health
//
//  Created by 김건우 on 8/9/25.
//

import UIKit

final class StatusProgressBarView: UIView {

    /// 현재 프로그래스 바의 진행 값을 설정합니다.
    ///
    /// 현재 값이 nil이라면 IndicatorDot이 프로그래스 바 위에 표시되지 않습니다.
    var currentValue: Double? = 0.5 {
        didSet { self.setNeedsLayout() }
    }

    /// 프로그래스 바의 구간을 나누는 임계값 배열입니다.
    ///
    /// - Important: 전달되는 값의 개수는 `thresholdsColors`의 개수보다 **하나 더 많아야** 합니다.
    ///              그렇지 않으면 크래시가 발생합니다.
    var thresholdsValues: [Double] = [0.0, 0.3, 0.7, 1.0] {
        didSet { self.setNeedsLayout() }
    }

    /// 각 임계 구간에 적용할 색상 배열입니다.
    ///
    /// - Important: 전달되는 값의 개수는 `thresholdsValues`의 개수보다 **하나 적어야** 합니다.
    ///              그렇지 않으면 크래시가 발생합니다.
    var thresholdsColors: [UIColor] = [.systemGreen, .systemYellow, .systemRed] {
        didSet { self.setNeedsLayout() }
    }

    /// 진행 상태를 나타내는 인디케이터 점의 색상입니다.
    var indicatorDotColor: UIColor = .label {
        didSet { self.setNeedsLayout() }
    }

    /// 값이 높을수록 좋은 경우, 색상 배열(`thresholdsColors`)을 반대로 적용할지 여부를 결정합니다.
    ///
    /// - Note: 이 값을 `true`로 설정하는 대신, 이미 뒤집힌 순서의 `thresholdsColors` 배열을 직접 전달해도 무방합니다.
    var higherIsBetter: Bool = false {
        didSet { self.setNeedsLayout() }
    }

    /// 처음과 마지막 x축 값을 숨깁니다.
    var isHiddenFirstAndLastThreshold: Bool = false {
        didSet { self.setNeedsLayout() }
    }

    /// x축 레이블에 표시할 숫자 포맷터를 지정합니다.
    var numberFormatter: NumberFormatter? = nil {
        didSet { self.setNeedsLayout() }
    }

    /// 인디케이터 Dot의 가로/세로 크기를 나타냅니다.
    let dotSize: CGFloat = 10
    /// 프로그래스 바의 높이를 나타냅니다.
    let barHeight: CGFloat = 20

    private let indicatorDotView = UIView()
    private let progressBarView = UIView()
    private let xAxisLabelStackView = UIStackView()
    private var graphInConstruction = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(progressBarView)
        progressBarView.layer.masksToBounds = true
        progressBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressBarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressBarView.heightAnchor.constraint(equalToConstant: barHeight)
        ])
        
        addSubview(xAxisLabelStackView)
        xAxisLabelStackView.alignment = .center
        xAxisLabelStackView.distribution = .equalCentering
        xAxisLabelStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            xAxisLabelStackView.leadingAnchor.constraint(equalTo: progressBarView.leadingAnchor, constant: 4),
            xAxisLabelStackView.trailingAnchor.constraint(equalTo: progressBarView.trailingAnchor, constant: -4),
            xAxisLabelStackView.topAnchor.constraint(equalTo: progressBarView.bottomAnchor, constant: 4),
            xAxisLabelStackView.heightAnchor.constraint(equalToConstant: barHeight)
        ])

        registerForTraitChanges()
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        guard thresholdsColors.count == thresholdsValues.count - 1
        else { fatalError("count of thresholds must be one less than the count of colors") }
        constructProgressBarGraph()
    }
    
    private func constructProgressBarGraph() {
        guard !graphInConstruction else { return }
        graphInConstruction = true
        defer {
            graphInConstruction = false
        }

        progressBarView.setNeedsLayout()
        progressBarView.layoutIfNeeded()
        
        let maxValue = thresholdsValues.max() ?? 0.0
        let minValue = thresholdsValues.min() ?? 0.0
        
        progressBarView.subviews.forEach { $0.removeFromSuperview() }
        progressBarView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        xAxisLabelStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        xAxisLabelStackView.subviews.forEach { $0.removeFromSuperview() }
        
        addGradientLayer(to: progressBarView)
        progressBarView.layer.cornerRadius = progressBarView.bounds.height / 2.0

        let dotParentView = UIView()
        add(parentView: dotParentView)

        if let currentValue = currentValue {
            thresholdsValues.enumerated().forEach { offset, value in
                let xAxisLabel = UILabel()
                add(
                    label: xAxisLabel,
                    xAixsStackView: xAxisLabelStackView,
                    value: value
                )

                if isHiddenFirstAndLastThreshold &&
                    (offset == 0 || offset == thresholdsValues.count - 1) {
                    xAxisLabel.textColor = .clear
                }
            }
            
            let indicatorDotView = UIView()
            add(
                indicator: indicatorDotView,
                parentView: dotParentView,
                currentValue: currentValue,
                minValue: minValue,
                maxValue: maxValue
            )
        }
    }
    
    private func add(
        label: UILabel,
        xAixsStackView: UIStackView,
        value: Double
    ) {
        if let formatter = numberFormatter { label.text = formatter.string(for: value) }
        else { label.text = value.formatted() }
        label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        xAxisLabelStackView.addArrangedSubview(label)
    }

    private func add(parentView: UIView) {
        addSubview(parentView)
        parentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            parentView.leadingAnchor.constraint(equalTo: progressBarView.leadingAnchor, constant: 12),
            parentView.trailingAnchor.constraint(equalTo: progressBarView.trailingAnchor, constant: -12),
            parentView.bottomAnchor.constraint(equalTo: progressBarView.topAnchor, constant: -8),
            parentView.heightAnchor.constraint(equalToConstant: dotSize)
        ])
    }

    private func add(
        indicator dot: UIView,
        parentView: UIView,
        currentValue: Double,
        minValue: Double,
        maxValue: Double
    ) {
        parentView.setNeedsLayout()
        parentView.layoutIfNeeded()

        parentView.addSubview(dot)
        dot.layer.cornerRadius = dotSize / 2
        dot.backgroundColor = indicatorDotColor
        dot.translatesAutoresizingMaskIntoConstraints = false
        
        // currentValue를 0~1 범위의 비율 값으로 변환합니다.
        let range = max(maxValue - minValue, 1e-9) // 구간의 전체 길이 계산
        let t = (currentValue - minValue) / range  // 시작점으로부터의 거리를 전체 길이로 나누어 진행 비율 계산
        let clamped = CGFloat(min(max(t, 0.0), 1.0))
        
        // 정규화한 값으로 dot이 위치할 leadingPadding을 계산합니다.
        let barWidth = parentView.bounds.width
        let leadingPadding = barWidth * clamped - (dotSize / 2.0)

        NSLayoutConstraint.activate([
            dot.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: dotSize),
            dot.heightAnchor.constraint(equalToConstant: dotSize)
        ])
        
        if leadingPadding < (dotSize / 2.0) {
            // 점의 중심이 시작점을 벗어나 왼쪽으로 가면 막대의 시작점에 위치시킵니다.
            dot.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 0).isActive = true
        } else if leadingPadding >= barWidth - (dotSize / 2.0) {
            // 점의 중심이 끝점을 벗어나 오른쪽으로 이동하면 막대의 끝점에 위치시킵니다.
            dot.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: barWidth - dotSize).isActive = true
        } else {
            // 점의 중심이 정상 범위 내라면 계산된 위치에 위치시킵니다.
            dot.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: leadingPadding).isActive = true
        }
    }
    
    private func addGradientLayer(to view: UIView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        var colors = thresholdsColors.flatMap { [$0.cgColor, $0.cgColor] }
        if higherIsBetter { colors = colors.reversed() }
        gradientLayer.colors = colors

        // 처음과 마지막 색상을 제외한 중간 색상이 차지하는 너비 비율
        let segmentFraction = 1.0 / Double(thresholdsColors.count)
        // 각 색상 사이에 자연스러운 그라디언트 효과를 주기 위해 겹침 비율
        let overlapFraction = segmentFraction * 0.15
        
        // 각 색상이 차지하는 영역을 계산합니다.
        let locations: [NSNumber] = thresholdsColors.enumerated()
            .flatMap { offset, _ in
                let dOffset = Double(offset)
                let base = segmentFraction * dOffset

                if offset == 0 {
                    // 첫 번째 색상인 경우
                    return [0.0, segmentFraction - overlapFraction]
                } else if offset == thresholdsColors.count - 1 {
                    // 마지막에 위치한 색상인 경우
                    return [base + overlapFraction, 1.0]
                } else {
                    // 중간에 위치한 색상인 경우
                    return [base + overlapFraction,
                            base + segmentFraction - overlapFraction]
                    // Note: - 중간에 위치한 색상 사이에 자연스러운 그라디언트 효과를 주기 위해
                    // overlapFraction을 더하고 빼줍니다.
                }
            }
            .map { NSNumber(value: $0) }
        gradientLayer.locations = locations

        view.layer.addSublayer(gradientLayer)
    }
}
