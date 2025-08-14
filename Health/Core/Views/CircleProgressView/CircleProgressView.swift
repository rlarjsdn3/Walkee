//
//  CircleProgressView.swift
//  ProgessBarProject
//
//  Created by 김건우 on 8/2/25.
//

import UIKit

final class CircleProgressView: CoreView {

    private var foregroundGradientLayer: CALayer?
    private var backgroundGradientLayer: CALayer?

    private let containerStackView = UIStackView()
    
    private let progressStackView = UIStackView()
    private let todayLabel = UILabel()
    private let percentageLabel = UILabel()
    
    private let stepCountStackView = UIStackView()
    private let stepTitleLabel = UILabel()
    private let stepProgressLabel = UILabel()
    
    private var padding: CGFloat {
        max(foregroundLineWidth, backgroundLineWidth) / 2.0
    }

    /// 전체 목표 값을 나타냅니다. 진행률 계산 시 분모로 사용됩니다.
    var totalValue: Double = 1 {
        didSet { self.setNeedsLayout() }
    }

    /// 현재 진행 중인 값을 나타냅니다. 진행률 계산 시 분자로 사용됩니다.
    var currentValue: Double? = nil {
        didSet { self.setNeedsLayout() }
    }

    /// 진행률 원형 선의 두께입니다.
    var foregroundLineWidth: CGFloat = 12 {
        didSet { self.setNeedsLayout() }
    }

    /// 밝은 모드에서 사용되는 진행률 원형 선의 색상 배열입니다.
    ///
    /// 단색으로 표시할 경우 색상 하나만 전달하면 되며,
    /// 색상을 하나도 전달하지 않으면 런타임 오류가 발생합니다.
    var foregroundLightColors: [UIColor] = [.accent, .segSelected, .accent] {
        didSet { self.setNeedsLayout() }
    }

    /// 어두운 모드에서 사용되는 진행률 원형 선의 색상 배열입니다.
    ///
    /// 단색으로 표시할 경우 색상 하나만 전달하면 되며,
    /// 색상을 하나도 전달하지 않으면 런타임 오류가 발생합니다.
    var foregroundDarkColors: [UIColor] = [.accent, .segSelected, .accent] {
        didSet { self.setNeedsLayout() }
    }

    /// 배경 원형 선의 두께입니다.
    var backgroundLineWidth: CGFloat = 12 {
        didSet { self.setNeedsLayout() }
    }

    /// 밝은 모드에서 사용되는 배경 원형 선의 색상 배열입니다.
    ///
    /// 단색으로 표시할 경우 색상 하나만 전달하면 되며,
    /// 색상을 하나도 전달하지 않으면 런타임 오류가 발생합니다.
    var backgroundLightColors: [UIColor] = [.systemGray5] {
        didSet { self.setNeedsLayout() }
    }

    /// 어두운 모드에서 사용되는 배경 원형 선의 색상 배열입니다.
    ///
    /// 단색으로 표시할 경우 색상 하나만 전달하면 되며,
    /// 색상을 하나도 전달하지 않으면 런타임 오류가 발생합니다.
    var backgroundDarkColors: [UIColor] = [.systemGray5] {
        didSet { self.setNeedsLayout() }
    }

    /// 내부 레이블 텍스트의 크기를 조정하는 비율 값입니다.
    var fontScale: CGFloat = 1.0 {
        didSet { self.updateContainerScale(fontScale) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForTraitChanges()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForTraitChanges()
    }
    
    // 진행 상태 관련 속성(currentValue, totalValue, 선 굵기 및 색상 등)이 변경되면,
    // setNeedsLayout()을 통해 layoutSubviews()가 호출되고,
    // 이 시점에서 기존 레이어를 제거하고 경로(Path)를 다시 그립니다.
    // 레이블 텍스트도 이와 함께 갱신합니다. (다른 적절한 업데이트 시점이 없기 때문입니다)
    override func layoutSubviews() {
        drawStrokeCircle()

        if let currentValue = currentValue {
            var percentageValue = currentValue / totalValue
            if percentageValue > 1 { percentageValue = 1 }
            percentageLabel.text = percentageValue
                .formatted(.percent.precision(.fractionLength(0)))

            let progressString = "\(currentValue.formatted()) / \(totalValue.formatted())"
            if let slashIndex = progressString.firstIndex(of: "/") {
                let index = progressString.index(after: slashIndex)
                stepProgressLabel.attributedText = NSAttributedString(string: progressString)
                    .foregroundColor(.systemMint, to: progressString[index...])
            } else {
                stepProgressLabel.text = "-"
            }
        } else {
            percentageLabel.text = "-"
            stepProgressLabel.text = "-"
        }
    }

    override func setupHierarchy() {
        addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(progressStackView)
        progressStackView.addArrangedSubviews(todayLabel, percentageLabel)
        
        containerStackView.addArrangedSubview(stepCountStackView)
        stepCountStackView.addArrangedSubviews(stepTitleLabel, stepProgressLabel)
    }
    
    override func setupAttribute() {
        backgroundColor = .clear

        containerStackView.axis = .vertical
        containerStackView.spacing = 16
        containerStackView.distribution = .equalCentering
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        
        progressStackView.axis = .vertical
        progressStackView.spacing = 2
        progressStackView.distribution = .fill
        
        stepCountStackView.axis = .vertical
        stepCountStackView.spacing = 6
        stepCountStackView.distribution = .fill
        
        todayLabel.text = "오늘"
        todayLabel.textColor = .accent
        todayLabel.font = .preferredFont(forTextStyle: .headline)
        todayLabel.textAlignment = .center
        
        percentageLabel.text = "86%"
        percentageLabel.textColor = .label
        percentageLabel.font = .preferredFont(forTextStyle: .largeTitle)
        percentageLabel.textAlignment = .center
        
        stepTitleLabel.text = "걸음 수"
        stepTitleLabel.textColor = .label
        stepTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        stepTitleLabel.textAlignment = .center
        
        stepProgressLabel.text = "6,200 / 8,000"
        stepProgressLabel.textColor = .label
        stepProgressLabel.font = .preferredFont(forTextStyle: .body)
        stepProgressLabel.textAlignment = .center
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    private func registerForTraitChanges() {
        // 인터페이스 스타일(light/dark)이 변경될 때 레이아웃을 다시 그리도록 등록합니다.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.setNeedsLayout()
        }
    }

    private func updateContainerScale(_ scale: CGFloat) {
        containerStackView.transform = CGAffineTransform(
            scaleX: scale,
            y: scale
        )
    }

    private func drawStrokeCircle() {
        let adjustedStartAngle = -90.radian
        
        drawStrokeCircle(
            in: &backgroundGradientLayer,
            startAngle: 0.radian,
            endAngle: 360.radian,
            lightStrokeColors: backgroundLightColors,
            darkStrokeColors: backgroundDarkColors,
            lineWidth: backgroundLineWidth
        )

        if let currentValue = currentValue {
            let calculatedEndAngle = ((currentValue / totalValue) * 360.0 - 90.0).radian
            drawStrokeCircle(
                in: &foregroundGradientLayer,
                startAngle: adjustedStartAngle,
                endAngle: calculatedEndAngle,
                lightStrokeColors: foregroundLightColors,
                darkStrokeColors: foregroundDarkColors,
                lineWidth: foregroundLineWidth
            )
        }
    }
}

extension CircleProgressView {

    private func drawStrokeCircle(
        in layer: inout CALayer?,
        startAngle startRadian: Double,
        endAngle endRadian: Double,
        lightStrokeColors: [UIColor],
        darkStrokeColors: [UIColor],
        lineWidth: CGFloat
    ) {
        assert(!lightStrokeColors.isEmpty || !darkStrokeColors.isEmpty)

        layer?.removeFromSuperlayer()

        let diameter = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circlePath = CGMutablePath()
        circlePath.addArc(
            center: center,
            radius: diameter / 2 - padding,
            startAngle: startRadian,
            endAngle: endRadian,
            clockwise: false
        )

        let shapeMask = CAShapeLayer()
        shapeMask.path = circlePath
        shapeMask.fillColor = UIColor.clear.cgColor
        shapeMask.strokeColor = UIColor.black.cgColor
        shapeMask.lineWidth = lineWidth
        shapeMask.lineCap = .round

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer.mask = shapeMask

        var colors: [CGColor] = traitCollection.userInterfaceStyle == .dark
        ? darkStrokeColors.map { $0.cgColor }
        : lightStrokeColors.map { $0.cgColor }
        // 색상이 하나뿐인 경우, 동일한 색상을 복제하여 배열에 추가합니다.
        // (GradientLayer는 최소 두 개 이상의 색상이 있어야 올바르게 표시됩니다.)
        if colors.count <= 1 { colors.append(contentsOf: colors) }
        gradientLayer.colors = colors

        layer = gradientLayer
        self.layer.addSublayer(gradientLayer)
    }
}
