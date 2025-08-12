//
//  HealthInfoCardCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import HealthKit

final class HealthInfoCardCellViewModel {

    let anchorDate: Date
    let cardType: DashboardCardType
    let age: Int

    @Injected var healthService: (any HealthService)

    /// 주어진 기준 날짜, 카드 타입, 나이로 인스턴스를 초기화합니다.
    ///
    /// - Parameters:
    ///   - anchorDate: 데이터를 조회할 기준 날짜입니다. 기본값은 현재 시각입니다.
    ///   - cardType: 대시보드 카드의 유형입니다.
    ///   - age: 사용자의 나이입니다.
    init(
        anchorDate: Date = .now,
        cardType: DashboardCardType,
        age: Int
    ) {
        self.anchorDate = anchorDate
        self.cardType = cardType
        self.age = age
    }

    /// 기준 시각으로부터 최근 14일간의 HealthKit 통계 데이터를 비동기적으로 조회합니다.
    ///
    /// - Parameter options: HealthKit 통계 조회 시 사용할 옵션입니다.
    /// - Returns: 지정한 기간과 옵션에 해당하는 `HealthKitData` 객체를 반환합니다.
    /// - Throws: HealthKit 데이터 조회에 실패할 경우 오류를 던집니다.
    func fetchStatisticsHealthKitData(options: HKStatisticsOptions) async throws -> HKData {
        let startDate = (anchorDate.addingDays(-14) ?? anchorDate).startOfDay()

        return try await healthService.fetchStatistics(
            for: cardType.quantityTypeIdentifier,
            from: startDate,
            to: anchorDate.endOfDay(),
            options: options,
            unit: cardType.unit
        )
    }

    /// 주어진 측정값을 사용자의 나이와 카드 타입 기준에 따라 보행 상태로 평가합니다.
    ///
    /// - Parameter value: 평가할 측정값입니다.
    /// - Returns: 평가된 보행 상태(`GaitStatus`)를 반환합니다.
    func evaluateGaitStatus(_ value: Double) -> DashboardCardType.GaitStatus {
        cardType.status(value, age: age)
    }
}

extension HealthInfoCardCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    nonisolated static func == (lhs: HealthInfoCardCellViewModel, rhs: HealthInfoCardCellViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
