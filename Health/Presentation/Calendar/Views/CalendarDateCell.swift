import UIKit

final class CalendarDateCell: CoreCollectionViewCell {

    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var dateLabel: UILabel!

    @IBOutlet weak var circleViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var circleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var circleViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var circleViewTrailingConstraint: NSLayoutConstraint!

    private let progressBar = CalendarProgressBar()
    private let borderLayer = CAShapeLayer()

    private var previousInset: CGFloat?
    private var isBlankCell = false
    private var isCompletedCell = false

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

    private func updateCircleViewConstraints(inset: CGFloat) {
        circleViewTopConstraint.constant = inset
        circleViewBottomConstraint.constant = inset
        circleViewLeadingConstraint.constant = inset
        circleViewTrailingConstraint.constant = inset
    }

    private func configureCircleViewUI() {
        circleView.applyCornerStyle(.circular) // 가로/세로 전환시
        updateBorderLayer()
    }

    private func updateBorderLayer() {
        let shouldShowBorder = traitCollection.userInterfaceStyle == .light && !isBlankCell && !isCompletedCell

        if shouldShowBorder {
            let borderWidth = bounds.width * 0.08
            let radius = (min(circleView.bounds.width, circleView.bounds.height) - borderWidth) / 2
            let path = UIBezierPath(
                arcCenter: CGPoint(x: circleView.bounds.midX, y: circleView.bounds.midY),
                radius: radius,
                startAngle: 0,
                endAngle: CGFloat.pi * 2,
                clockwise: true
            )

            borderLayer.path = path.cgPath
            borderLayer.strokeColor = UIColor(named: "boxBgLightModeStrokeColor")?.cgColor
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

    func configure(date: Date, currentSteps: Int, goalSteps: Int) {
        // 달력상 빈 날짜일 때
        if date == .distantPast {
            isBlankCell = true
            isCompletedCell = false
            configureForBlank()
            return
        }

        isBlankCell = false
        circleView.applyCornerStyle(.circular) // 초기 진입시
        dateLabel.text = "\(date.day)"

        isCompletedCell = currentSteps >= goalSteps

        if isCompletedCell {
            circleView.backgroundColor = UIColor.accent
            progressBar.isHidden = true
        } else {
            circleView.backgroundColor = UIColor.boxBg
            progressBar.isHidden = false
            progressBar.progress = CGFloat(currentSteps) / CGFloat(goalSteps)
        }
        updateBorderLayer()
    }

    private func configureForBlank() {
        circleView.backgroundColor = .clear
        dateLabel.text = ""
        progressBar.isHidden = true
        updateBorderLayer()
    }
}
