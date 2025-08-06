import UIKit

final class CalendarMonthCell: CoreCollectionViewCell {

    @IBOutlet weak var yearMonthLabel: UILabel!
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var dateCollectionViewHeightConstraint: NSLayoutConstraint!
    
    private var datesWithBlank: [Date] = []

    override func setupAttribute() {
        super.setupAttribute()
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        dateCollectionView.collectionViewLayout = createLayout()
        dateCollectionView.register(
            CalendarDateCell.nib,
            forCellWithReuseIdentifier: CalendarDateCell.id
        )
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 7.0),
            heightDimension: .fractionalWidth(1.0 / 7.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / 7.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: Array(repeating: item, count: 7)
        )

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }

    func configure(year: Int, month: Int) {
        let calendar = Calendar.gregorian
        guard let firstDay = DateComponents(calendar: calendar, year: year, month: month).date else {
            return
        }

        yearMonthLabel.text = firstDay.formatted(using: "yyyy년 M월")

		// 1일 앞의 빈칸을 포함한 모든 날짜
        let dates = firstDay.datesInMonth(using: calendar)
        let weekday = calendar.component(.weekday, from: firstDay)
        datesWithBlank = Array(repeating: Date.distantPast, count: weekday - 1) + dates

        // 셀 크기 동적 조정을 위한 dateCollectionView 높이 계산
        let totalItems = datesWithBlank.count
        let numberOfRows = Int(ceil(Double(totalItems) / 7.0))
        let itemWidth = UIScreen.main.bounds.width / 7
        dateCollectionViewHeightConstraint.constant = CGFloat(numberOfRows) * itemWidth

        dateCollectionView.reloadData()
    }
}

extension CalendarMonthCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        datesWithBlank.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarDateCell.id,
            for: indexPath
        ) as? CalendarDateCell else {
            return UICollectionViewCell()
        }

        let date = datesWithBlank[indexPath.item]

        // TODO: 실제 걸음 데이터로 수정
        let current = Int.random(in: 0 ... 15000)
        let goal = 10000

        cell.configure(date: date, currentSteps: current, goalSteps: goal)

        return cell
    }
}
