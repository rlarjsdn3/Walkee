import UIKit

/// 캘린더의 개별 날짜를 표시하는 셀
///
/// `CalendarDateCell`은 하나의 날짜와 해당 날짜의 걸음 수 진행률을 표시합니다.
/// 목표 달성 여부에 따라 다른 시각적 스타일을 적용하며, 사용자 인터랙션을 지원합니다.
///
/// ## 시각적 상태
/// - **빈 셀**: 월의 첫째 날 이전 빈 공간
/// - **데이터 없음**: 권한이 없거나 데이터가 없는 날짜
/// - **진행 중**: 목표 미달성 시 진행률 바 표시
/// - **완료**: 목표 달성 시 강조 색상 표시
final class CalendarDateCell: CoreCollectionViewCell {

    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var dateLabel: UILabel!

    @IBOutlet weak var circleViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var circleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var circleViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var circleViewTrailingConstraint: NSLayoutConstraint!

    private let progressBar = CalendarProgressBar()
    private let borderLayer = CAShapeLayer()

    /// 이전 inset 값 (불필요한 레이아웃 업데이트 방지용)
    private var previousInset: CGFloat?

    /// 빈 셀 여부 (월의 첫째 날 이전 공간)
    private var isBlank = false

    /// 목표 달성 여부
    private var isCompleted = false

    /// 셀의 선택 가능 여부
    ///
    /// 빈 셀이나 데이터가 없는 날짜는 선택할 수 없습니다.
    private(set) var isSelectable = false

    override func setupHierarchy() {
        super.setupHierarchy()

        circleView.addSubview(progressBar)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: CalendarDateCell, previousTraitCollection) in
            self.updateBorderLayer()
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        progressBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressBar.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            progressBar.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            progressBar.widthAnchor.constraint(equalTo: circleView.widthAnchor),
            progressBar.heightAnchor.constraint(equalTo: circleView.heightAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let insetRatio: CGFloat = 0.1
        let inset = bounds.width * insetRatio

        // 불필요한 layout 반복 방지
        if previousInset != inset {
            updateCircleViewConstraints(inset: inset)
            previousInset = inset
        }

        configureCircleViewUI()
    }

    /// 셀 재사용 시 이전 상태를 초기화합니다.
    ///
    /// 컬렉션 뷰에서 셀을 재사용할 때 이전 데이터의 영향을 제거하여
    /// 올바른 초기 상태를 보장합니다.
    override func prepareForReuse() {
        super.prepareForReuse()
        isBlank = false
        isCompleted = false
        isSelectable = false
        contentView.alpha = 1.0
        contentView.transform = .identity
    }

    /// 셀이 하이라이트될 때의 시각적 피드백을 제공합니다.
    ///
    /// 선택 가능한 셀에만 스케일과 투명도 애니메이션을 적용하여
    /// 사용자 터치에 대한 즉각적인 시각적 반응을 제공합니다.
    override var isHighlighted: Bool {
        didSet {
            guard isSelectable else { return }

            let alpha: CGFloat = isHighlighted ? 0.75 : 1.0
            let scale: CGFloat = isHighlighted ? 0.95 : 1.0

            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.allowUserInteraction, .curveEaseInOut]
            ) {
                self.contentView.alpha = alpha
                self.contentView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }

    /// 날짜와 걸음 수 데이터로 셀을 구성합니다.
    ///
    /// - Parameters:
    ///   - date: 표시할 날짜 (`Date.distantPast`인 경우 빈 셀로 처리)
    ///   - currentSteps: 해당 날짜의 현재 걸음 수 (nil인 경우 데이터 없음)
    ///   - goalSteps: 해당 날짜의 목표 걸음 수 (nil인 경우 데이터 없음)
    ///
    /// ## 셀 상태별 처리
    /// - **빈 셀**: `date`가 `Date.distantPast`인 경우
    /// - **데이터 없음**: `currentSteps` 또는 `goalSteps`가 nil인 경우
    /// - **목표 달성**: `currentSteps >= goalSteps`인 경우 강조 색상 적용
    /// - **진행 중**: 목표 미달성 시 진행률 바 표시
    func configure(date: Date, currentSteps: Int?, goalSteps: Int?) {
        // 빈 셀 처리
        if date == .distantPast {
            isBlank = true
            isSelectable = false
            configureForBlank()
            return
        }

        dateLabel.text = "\(date.day)"

        // 데이터 없음 처리
        guard let current = currentSteps, let goal = goalSteps else {
            circleView.backgroundColor = UIColor.boxBg
            progressBar.isHidden = true
            updateBorderLayer()
            return
        }

        isSelectable = true
        isCompleted = current >= goal

        if isCompleted {
            circleView.backgroundColor = UIColor.accent
            progressBar.isHidden = true
        } else {
            circleView.backgroundColor = UIColor.boxBg
            progressBar.isHidden = false
            progressBar.progress = CGFloat(current) / CGFloat(goal)
        }
        updateBorderLayer()
    }
}

// MARK: - Private Configuration Methods
private extension CalendarDateCell {

    /// 원형 뷰의 제약 조건을 업데이트합니다
    ///
    /// - Parameter inset: 셀 경계로부터의 여백
    ///
    /// 모든 방향에 동일한 inset을 적용하여 정사각형 원형 뷰를 만듭니다.
    func updateCircleViewConstraints(inset: CGFloat) {
        circleViewTopConstraint.constant = inset
        circleViewBottomConstraint.constant = inset
        circleViewLeadingConstraint.constant = inset
        circleViewTrailingConstraint.constant = inset
    }

    /// 원형 뷰의 UI 스타일을 구성합니다.
    ///
    /// 원형 모양을 적용하고 테두리 레이어를 업데이트합니다.
    func configureCircleViewUI() {
        circleView.applyCornerStyle(.circular)
        updateBorderLayer()
    }

    /// 빈 셀의 상태를 구성합니다.
    ///
    /// 빈 셀은 투명한 배경과 빈 텍스트를 가지며,
    /// 진행률 바와 테두리를 숨깁니다.
    func configureForBlank() {
        circleView.backgroundColor = .clear
        dateLabel.text = ""
        progressBar.isHidden = true
        updateBorderLayer()
    }

    /// 테두리 레이어의 표시 여부와 스타일을 업데이트합니다.
    ///
    /// 선택 가능하면서 목표를 달성하지 않은 날짜에만 테두리를 표시합니다.
    /// 다크/라이트 모드 변경 시에도 적절한 색상으로 업데이트됩니다.
    ///
    /// ## 테두리 표시 조건
    /// - 선택 가능한 날짜 (`isSelectable == true`)
    /// - 목표 미달성 상태 (`isCompleted == false`)
    func updateBorderLayer() {
        let shouldShowBorder = isSelectable && !isCompleted

        if shouldShowBorder {
            let borderWidth = circleView.bounds.width * 0.08
            let radius = (min(circleView.bounds.width, circleView.bounds.height) - borderWidth) / 2
            let path = UIBezierPath(
                arcCenter: CGPoint(x: circleView.bounds.midX, y: circleView.bounds.midY),
                radius: radius,
                startAngle: 0,
                endAngle: CGFloat.pi * 2,
                clockwise: true
            )

            borderLayer.path = path.cgPath
            borderLayer.strokeColor = UIColor(named: "calendarDateStrokeColor")?.cgColor
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.lineWidth = borderWidth
            borderLayer.isHidden = false

            if borderLayer.superlayer == nil {
                circleView.layer.insertSublayer(borderLayer, below: progressBar.layer)
            }
        } else {
            borderLayer.isHidden = true
        }
    }
}
