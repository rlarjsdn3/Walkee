//
//  DailyActivitySummaryViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Foundation
import HealthKit

typealias HealthKitData = (startDate: Date, endDate: Date, value: Double)

final class HealthInfoStackCellViewModel {

    let anchorDate: Date
    let stackType: DashboardStackType

    @Injected var healthService: (any HealthService)

    /// 주어진 기준 날짜와 스택 타입으로 인스턴스를 초기화합니다.
    ///
    /// - Parameters:
    ///   - anchorDate: 데이터를 조회할 기준 날짜입니다. 기본값은 현재 시각입니다.
    ///   - stackType: 대시보드 스택의 유형입니다.
    init(
        anchorDate: Date = .now,
        stackType: DashboardStackType
    ) {
        self.anchorDate = anchorDate
        self.stackType = stackType
    }

    /// 기준 시각 하루 동안의 HealthKit 통계 데이터를 비동기적으로 조회합니다.
    ///
    /// - Parameter options: HealthKit 통계 조회 시 사용할 옵션입니다. 기본값은 `.cumulativeSum`입니다.
    /// - Returns: 조회된 `HealthKitData` 객체를 반환합니다.
    /// - Throws: HealthKit 데이터 조회에 실패할 경우 오류를 던집니다.
    func fetchStatisticsHKData(options: HKStatisticsOptions = .cumulativeSum) async throws -> HealthKitData {
        try await healthService.fetchStatistics(
            for: stackType.quantityTypeIdentifier,
            from: anchorDate.startOfDay(),
            to: anchorDate.endOfDay(),
            options: options,
            unit: stackType.unit
        )
    }

    /// 기준 시각으로부터 최근 7일간의 HealthKit 통계 컬렉션 데이터를 비동기적으로 조회합니다.
    ///
    /// - Parameters:
    ///   - options: HealthKit 통계 조회 시 사용할 옵션입니다.
    ///   - intervalComponents: 통계 데이터를 구간별로 나누는 시간 간격입니다. 기본값은 1일입니다.
    /// - Returns: 조회된 `HealthKitData` 객체 배열을 반환합니다.
    /// - Throws: HealthKit 데이터 조회에 실패할 경우 오류를 던집니다.
    func fetchStatisticsCollectionHKData(
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents = .init(day: 1)
    ) async throws -> [HealthKitData] {
        let startDate = (anchorDate.addingDays(-7) ?? anchorDate).startOfDay()

        return try await healthService.fetchStatisticsCollection(
            for: stackType.quantityTypeIdentifier,
            from: startDate,
            to: anchorDate.endOfDay(),
            options: options,
            interval: intervalComponents,
            unit: stackType.unit
        )
    }
}

extension HealthInfoStackCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    nonisolated static func == (lhs: HealthInfoStackCellViewModel, rhs: HealthInfoStackCellViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
