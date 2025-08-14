import Foundation

/// 특정 날짜의 걸음 수 정보를 나타내는 스냅샷
///
/// 이 구조체는 특정 날짜의 현재 걸음 수와 목표 걸음 수를 포함합니다.
struct DailyStepSnapshot: Sendable, Hashable {
    let current: Int
    let goal: Int
}

/// 달력에서 사용할 걸음 수 데이터를 제공하는 프로토콜
protocol CalendarStepProvider: Sendable {
    func fetchMonthSnapshots(year: Int, month: Int) async -> [Date: DailyStepSnapshot]
}

/// 테스트 및 개발용 목 걸음 수 데이터 제공자
///
/// 이 구조체는 `CalendarStepProvider` 프로토콜을 구현하여
/// 랜덤한 걸음 수 데이터를 생성하고 제공합니다.
struct MockCalendarStepProvider: CalendarStepProvider {

    /// 기본 목표 걸음 수
    private let defaultGoal: Int

    /// 미리 생성된 걸음 수 데이터 캐시
    private let cache: [Date: DailyStepSnapshot]

    /// MockCalendarStepProvider를 초기화합니다.
    ///
    /// - Parameters:
    ///   - defaultGoal: 기본 목표 걸음 수. 기본값은 10,000보입니다.
    ///   - period: 생성할 데이터의 기간(일 단위). 기본값은 365일입니다.
    ///
    /// - Note: 초기화 시점에서 과거 `period`일 동안의 랜덤 데이터를 생성합니다.
    ///         각 날짜의 걸음 수는 0부터 15,000 사이의 랜덤 값으로 설정됩니다.
    init(
        defaultGoal: Int = 10_000,
        period: Int = 365
    ) {
        self.defaultGoal = defaultGoal

        let today = Date().startOfDay()
        var snapshots: [Date: DailyStepSnapshot] = [:]
        snapshots.reserveCapacity(period + 5)

        for i in 0..<period {
            guard let date = today.addingDays(-i) else { continue }
            let current = Int.random(in: 0 ... 15000)
            snapshots[date] = DailyStepSnapshot(current: current, goal: defaultGoal)
        }
        self.cache = snapshots
    }

    /// 특정 연도와 월의 걸음 수 스냅샷을 비동기로 가져옵니다.
    ///
    /// 이 메서드는 캐시된 데이터에서 해당 월의 데이터를 필터링하여 반환합니다.
    ///
    /// - Parameters:
    ///   - year: 조회할 연도
    ///   - month: 조회할 월 (1-12)
    /// - Returns: 날짜를 키로 하는 걸음 수 스냅샷 딕셔너리
    ///
    /// - Important: 미래 날짜에 대한 데이터는 제외됩니다.
    /// - Note: 유효하지 않은 연도/월 조합이 전달되면 빈 딕셔너리를 반환합니다.
    func fetchMonthSnapshots(year: Int, month: Int) async -> [Date: DailyStepSnapshot] {
        guard let firstDay = Calendar.current.date(from: DateComponents(year: year, month: month)) else {
            return [:]
        }

        let today = Date().startOfDay()
        var snapshots: [Date: DailyStepSnapshot] = [:]

        for date in firstDay.datesInMonth() {
            let normalizedDate = date.startOfDay()

            if normalizedDate > today { continue } // 미래 데이터는 제외

            if let snapshot = cache[normalizedDate] {
                snapshots[normalizedDate] = snapshot
            }
        }
        return snapshots
    }
}
