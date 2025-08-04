//
//  DashedView.swift
//  BarChartViewProject
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

final class DashedView: CoreView {

    private var dashedLayer: CAShapeLayer?

    /// 점선의 두께입니다.
    var lineWidth: CGFloat = 1 {
        didSet { self.setNeedsLayout() }
    }

    /// 점선의 색상입니다.
    var strokeColor: UIColor? = .systemGray {
        didSet { self.setNeedsLayout() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        dashedLayer?.removeFromSuperlayer()

        let dashedPath = CGMutablePath()
        dashedPath.addLines(
            between: [
                CGPoint(x: 0, y: self.bounds.height / 2),
                CGPoint(x: self.bounds.width, y: self.bounds.height / 2)
            ]
        )

        let dashedLayer = CAShapeLayer()
        dashedLayer.frame = bounds
        dashedLayer.fillColor = UIColor.clear.cgColor
        dashedLayer.strokeColor = strokeColor?.cgColor
        dashedLayer.lineWidth = lineWidth
        dashedLayer.lineDashPattern = [2, 3]
        dashedLayer.path = dashedPath

        self.dashedLayer = dashedLayer
        self.layer.addSublayer(dashedLayer)

    }
}
