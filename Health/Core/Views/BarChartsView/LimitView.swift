//
//  LimitView.swift
//  BarChartViewProject
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

final class LimitView: CoreView {

    private let limitStackView = UIStackView()
    private let limitLabel = UILabel()
    private let dashedView = DashedView()

    /// 표시할 라벨 텍스트입니다.
    var text: String? {
        didSet { updateConfugurationIfNeeded() }
    }

    /// 제한선에 적용할 시각적 설정값입니다.
    var configuration: BarChartsView.Configuration? {
        didSet { updateConfugurationIfNeeded() }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: limitStackView.bounds.height
        )
    }

    override func setupHierarchy() {
        addSubview(limitStackView)
        limitStackView.addArrangedSubview(limitLabel)
        limitStackView.addArrangedSubview(dashedView)
    }

    override func setupAttribute() {
        limitStackView.axis = .vertical
        limitStackView.spacing = 2
        limitStackView.translatesAutoresizingMaskIntoConstraints = false

        limitLabel.textAlignment = .right
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            limitStackView.topAnchor.constraint(equalTo: topAnchor),
            limitStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            limitStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            limitStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateConfugurationIfNeeded() {
        guard let configuration = configuration else { return }
        limitLabel.text = text
        limitLabel.font = configuration.textStyle.limitLabelFont
        limitLabel.textColor = configuration.textStyle.limitLabelTint
        dashedView.lineWidth = configuration.dashedLineWidth
        dashedView.strokeColor = configuration.dashedLineStrokeColor
    }
}
