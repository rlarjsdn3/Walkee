//
//  DashboardBarChartsCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import HealthKit

enum BarChartsBackType {
    /// 기준 시점부터 n일 전까지 포함
    case daysBack(Int)
    /// 기준 시점부터 n개월 전까지 포함
    case monthsBack(Int)

    ///
    var count: Int {
        switch self {
        case let .daysBack(value), let .monthsBack(value):
            return max(0, abs(value))
        }
    }
}

final class DashboardBarChartsCellViewModel { // TODO: - Cell에서 처리하고 있는 HKData 페치 로직을 VC의 VM으로 빼보기

    let startDate: Date
    let endDate: Date
    let interval: DateComponents
    let backType: BarChartsBackType

    /// 섹션/막대 범위를 설명하는 헤더 타이틀
    var headerTitle: String {
        switch backType {
        case .daysBack(let n):   return "지난 \(max(0, abs(n)))일 간 걸음 수 분석"
        case .monthsBack(let n): return "지난 \(max(0, abs(n)))개월 간 걸음 수 분석"
        }
    }

    @Injected private var healthService: (any HealthService)

    ///
    private init(
        startDate: Date,
        endDate: Date,
        interval: DateComponents,
        backType: BarChartsBackType
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.interval = interval
        self.backType = backType
    }

    ///
    convenience init?(
        back backType: BarChartsBackType,
        reference: Date = .now
    ) {
        guard let result = Self.makeDateSpan(
            for: backType,
            reference: reference
        ) else { return nil }

        self.init(
            startDate: result.start,
            endDate: result.end,
            interval: result.interval,
            backType: backType
        )
    }

    ///
    func fetchStatisticsCollectionHKData(options: HKStatisticsOptions = .cumulativeSum) async throws -> [HealthKitData] {
        try await healthService.fetchStatisticsCollection(
            for: .stepCount,
            from: startDate,
            to: endDate,
            options: options,
            interval: interval,
            unit: .count()
        )
    }
}

extension DashboardBarChartsCellViewModel {

    private static func makeDateSpan(
        for backType: BarChartsBackType,
        reference: Date
    ) -> (start: Date, end: Date, interval: DateComponents)? {

        switch backType {
        case .daysBack(let value):
            let n = max(0, abs(value))

            // 기준: 오늘의 끝
            guard let endOfDay = reference.endOfDay() as Date?,
                  let startDate = endOfDay.addingDays(-n),
                  let endDate = endOfDay.endOfDay() as Date?
            else { return nil }

            return (start: startDate, end: endDate, interval: .init(day: 1))

        case .monthsBack(let value):
            let n = max(0, abs(value))

            // 기준: 이번 달의 끝
            guard let endOfMonth = reference.endOfMonth(),
                  let startDate = endOfMonth.addingMonths(-n),
                  let endDate = endOfMonth.endOfMonth()
            else { return nil }

            return (start: startDate, end: endDate, interval: .init(month: 1))
        }
    }
}

extension DashboardBarChartsCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    nonisolated static func == (lhs: DashboardBarChartsCellViewModel, rhs: DashboardBarChartsCellViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
