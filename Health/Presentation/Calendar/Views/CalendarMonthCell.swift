import UIKit

final class CalendarMonthCell: CoreCollectionViewCell {

    @IBOutlet weak var yearMonthLabel: UILabel!
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var dateCollectionViewHeightConstraint: NSLayoutConstraint!

    @Injected(.calendarStepService) private var stepService: CalendarStepService

    private var datesWithBlank: [Date] = []

    var onDateSelected: ((Date) -> Void)?

    override func setupAttribute() {
        super.setupAttribute()
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        dateCollectionView.collectionViewLayout = CalendarLayoutManager.createDateLayout()
        dateCollectionView.register(
            CalendarDateCell.nib,
            forCellWithReuseIdentifier: CalendarDateCell.id
        )
    }

    func configure(with monthData: CalendarMonthData) {
        setupMonthData(year: monthData.year, month: monthData.month)
    }

    private func setupMonthData(year: Int, month: Int) {
        let calendar = Calendar.gregorian
        guard let firstDay = DateComponents(calendar: calendar, year: year, month: month).date else {
            return
        }

        yearMonthLabel.text = firstDay.formatted(using: "yyyy년 M월")

		// 1일 앞의 빈칸을 포함한 모든 날짜
        let dates = firstDay.datesInMonth(using: calendar)
        let weekday = calendar.component(.weekday, from: firstDay)
        datesWithBlank = Array(repeating: Date.distantPast, count: weekday - 1) + dates

        dateCollectionView.layoutIfNeeded() // 현재 셀 폭 반영

        // 셀 크기 동적 조정을 위한 dateCollectionView 높이 계산
        let numberOfRows = 6
        let itemWidth = dateCollectionView.bounds.width / 7
        dateCollectionViewHeightConstraint.constant = CGFloat(numberOfRows) * itemWidth

        dateCollectionView.reloadData()
    }
}

extension CalendarMonthCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        datesWithBlank.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarDateCell.id, for: indexPath) as! CalendarDateCell
        let date = datesWithBlank[indexPath.item]

        if date == .distantPast || date > Date() {
            cell.configure(date: date, currentSteps: nil, goalSteps: nil)
        } else {
            let (current, goal) = stepService.steps(for: date)
            cell.configure(date: date, currentSteps: current, goalSteps: goal)
        }

        return cell
    }
}

extension CalendarMonthCell: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CalendarDateCell else {
            return false
        }
        let date = datesWithBlank[indexPath.item]
        return date != .distantPast && cell.isClickable
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = datesWithBlank[indexPath.item]
        guard date != .distantPast, date <= Date() else { return }
        onDateSelected?(date)
    }
}
