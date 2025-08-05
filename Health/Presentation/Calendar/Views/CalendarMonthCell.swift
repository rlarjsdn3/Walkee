import UIKit

final class CalendarMonthCell: CoreCollectionViewCell {
    @IBOutlet weak var yearMonthLabel: UILabel!

    func configure(year: Int, month: Int) {
        yearMonthLabel.text = "\(year)년 \(month)월"
    }
}
