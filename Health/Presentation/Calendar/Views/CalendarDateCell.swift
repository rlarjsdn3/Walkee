import UIKit

final class CalendarDateCell: CoreCollectionViewCell {

    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var dateLabel: UILabel!

    private let progressBar = CalendarProgressBar()

    override func setupHierarchy() {
        super.setupHierarchy()
        circleView.addSubview(progressBar)
    }

    override func setupAttribute() {
        super.setupAttribute()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
    }

    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            progressBar.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            progressBar.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            progressBar.widthAnchor.constraint(equalTo: circleView.widthAnchor),
            progressBar.heightAnchor.constraint(equalTo: circleView.heightAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.applyCornerStyle(.circular) // 가로/세로 전환시
    }

    func configure(date: Date, currentSteps: Int, goalSteps: Int) {
        // 달력상 빈 날짜일 때
        if date == .distantPast {
            configureForBlank()
            return
        }

        circleView.applyCornerStyle(.circular) // 초기 진입시
        dateLabel.text = "\(date.day)"
        progressBar.progress = CGFloat(currentSteps) / CGFloat(goalSteps)
        progressBar.isHidden = false

        let isCompleted = currentSteps >= goalSteps
        if isCompleted {
            circleView.backgroundColor = UIColor.white
            dateLabel.textColor = UIColor.black
        } else {
            circleView.backgroundColor = UIColor(hex: "#6A6A6A")
            dateLabel.textColor = UIColor.white
        }
    }

    private func configureForBlank() {
        circleView.backgroundColor = .clear
        dateLabel.text = ""
        progressBar.isHidden = true
    }
}
