import Foundation

struct DailyStepSnapshot: Sendable, Hashable {
    let current: Int
    let goal: Int
}

protocol CalendarStepProvider: Sendable {
    func fetchMonthSnapshots(year: Int, month: Int) async -> [Date: DailyStepSnapshot]
}

struct MockCalendarStepProvider: CalendarStepProvider {

    private let defaultGoal: Int
    private let cache: [Date: DailyStepSnapshot]

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
