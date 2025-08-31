import UIKit

/// 원형 진행률을 표시하는 커스텀 뷰
///
/// `CalendarProgressBar`는 걸음 수 목표 달성률을 시각적으로 나타내는 원형 진행률 바입니다.
/// 12시 방향에서 시작하여 시계 방향으로 진행률을 표시합니다.
final class CalendarProgressBar: CoreView {

    private let progressLayer = CAShapeLayer()

    /// 현재 진행률 (0.0 ~ 1.0)
    ///
    /// 값이 설정되면 즉시 시각적 업데이트가 이루어집니다.
    /// 0.0 미만이나 1.0 초과 값은 자동으로 범위 내로 제한됩니다.
    ///
    /// - Note: 암시적 애니메이션을 비활성화하여 즉시 업데이트됩니다.
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

    /// 레이아웃이 변경될 때 진행률 바의 경로와 스타일을 업데이트합니다.
    ///
    /// 뷰의 크기에 맞춰 원형 경로를 다시 계산하고,
    /// 선 두께와 색상을 설정합니다.
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
