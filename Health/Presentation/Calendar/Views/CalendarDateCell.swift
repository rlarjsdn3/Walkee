import UIKit

final class CalendarDateCell: CoreCollectionViewCell {

    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var dateLabel: UILabel!

    override func setupAttribute() {
        super.setupAttribute()
        circleView.applyCornerStyle(.circular)
    }

    func configure(date: Date) {
        if date == .distantPast {
            circleView.backgroundColor = .clear
            dateLabel.text = ""
        } else {
            circleView.backgroundColor = UIColor(hex: "#6A6A6A")
            dateLabel.text = "\(date.day)"
        }
    }
}
