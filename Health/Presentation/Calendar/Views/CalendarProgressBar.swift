import UIKit

final class CalendarProgressBar: CoreView {

    private let progressLayer = CAShapeLayer()

    var progress: CGFloat = 0 {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true) // 암시적 애니메이션 제거
            progressLayer.strokeEnd = min(max(progress, 0), 1)
            CATransaction.commit()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        backgroundColor = .clear
        layer.addSublayer(progressLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressLayer.frame = bounds

        let lineWidth = bounds.width * 0.08
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2

        let path = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.accent.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
    }
}
