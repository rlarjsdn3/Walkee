import UIKit

final class CalendarMonthCell: CoreCollectionViewCell {

    /// 월별 캘린더를 표시하는 컬렉션 뷰 셀
    ///
    /// `CalendarMonthCell`은 하나의 월에 해당하는 날짜들을 그리드 형태로 표시하며,
    /// 각 날짜의 걸음 수 데이터와 목표 달성률을 시각화합니다.
    @IBOutlet weak var yearMonthLabel: UILabel!
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var dateCollectionViewHeightConstraint: NSLayoutConstraint!

    @Injected(.calendarStepService) private var stepService: CalendarStepService

    /// 빈 공간을 포함한 전체 날짜 배열
    ///
    /// 월의 첫째 날 이전 빈 공간은 `Date.distantPast`로 채워집니다.
    /// 이를 통해 7×6 그리드에서 올바른 요일 위치에 날짜가 표시됩니다.
    private var datesWithBlank: [Date] = []

    /// 걸음 수 데이터 접근 권한 여부
    private var isStepCountAuthorized = false

    /// 날짜 선택 시 호출되는 클로저
    ///
    /// 선택된 날짜를 매개변수로 받아 상위 화면에서 처리할 수 있습니다.
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

    /// 월 데이터와 권한 상태로 셀을 구성합니다.
    ///
    /// - Parameters:
    ///   - monthData: 표시할 월의 년도와 월 정보
    ///   - isStepCountAuthorized: 걸음 수 데이터 접근 권한 여부
    ///
    /// 권한이 있는 경우 실제 걸음 수 데이터를 표시하고,
    /// 권한이 없는 경우 날짜만 표시합니다.
    func configure(with monthData: CalendarMonthData, isStepCountAuthorized: Bool) {
        self.isStepCountAuthorized = isStepCountAuthorized
        setupMonthData(year: monthData.year, month: monthData.month)
    }

    /// 특정 년월의 데이터를 설정하고 UI를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - year: 표시할 년도
    ///   - month: 표시할 월 (1-12)
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

// MARK: - UICollectionViewDataSource
extension CalendarMonthCell: UICollectionViewDataSource {

    /// 날짜 컬렉션 뷰의 아이템 개수를 반환합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 데이터를 요청하는 컬렉션 뷰
    ///   - section: 섹션 인덱스
    /// - Returns: 빈 공간을 포함한 전체 날짜 개수 (일반적으로 42개: 7×6)
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        datesWithBlank.count
    }

    /// 특정 인덱스의 날짜 셀을 구성하고 반환합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 셀을 요청하는 컬렉션 뷰
    ///   - indexPath: 셀의 위치
    /// - Returns: 구성된 `CalendarDateCell` 인스턴스
    ///
    /// 권한 상태에 따라 걸음 수 데이터 표시 여부가 결정됩니다:
    /// - 권한 있음: 실제 걸음 수와 목표값 표시
    /// - 권한 없음: 날짜만 표시
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarDateCell.id, for: indexPath) as! CalendarDateCell

        let date = datesWithBlank[indexPath.item]

        if isStepCountAuthorized {
            let (current, goal) = stepService.steps(for: date)
            cell.configure(date: date, currentSteps: current, goalSteps: goal)
        } else {
            cell.configure(date: date, currentSteps: nil, goalSteps: nil)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CalendarMonthCell: UICollectionViewDelegate {

    /// 날짜 셀의 선택 가능 여부를 결정합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 이벤트가 발생한 컬렉션 뷰
    ///   - indexPath: 선택하려는 셀의 위치
    /// - Returns: 셀의 선택 가능 여부
    ///
    /// 각 날짜 셀의 `isSelectable` 프로퍼티를 확인하여
    /// 빈 공간이나 데이터가 없는 날짜의 선택을 방지합니다.
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as! CalendarDateCell
        return cell.isSelectable
    }

    /// 날짜 셀이 선택되었을 때의 동작을 처리합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 이벤트가 발생한 컬렉션 뷰
    ///   - indexPath: 선택된 셀의 위치
    ///
    /// 선택된 날짜를 `onDateSelected` 클로저를 통해 상위 컴포넌트로 전달합니다.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = datesWithBlank[indexPath.item]
        onDateSelected?(date)
    }
}
