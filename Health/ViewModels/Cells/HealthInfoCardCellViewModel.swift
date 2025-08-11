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

    convenience init() { // 임시 코드
        self.init(anchorDate: .now, cardType: .walkingStepLength, age: 27)
    }

    ///
    init(
        anchorDate: Date = .now,
        cardType: DashboardCardType,
        age: Int
    ) {
        self.anchorDate = anchorDate
        self.cardType = cardType
        self.age = age
    }

    /// <#Description#>
    /// - Parameters:
    ///   - startDate: <#startDate description#>
    ///   - endDate: <#endDate description#>
    /// - Returns: <#description#>
    func fetchStatisticsHealthKitData(options: HKStatisticsOptions) async throws -> HealthKitData {
        try await healthService.fetchStatistics(
            for: cardType.quantityTypeIdentifier,
            from: anchorDate.startOfDay(),
            to: anchorDate.endOfDay(),
            options: options,
            unit: cardType.unit
        )
    }

    ///
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
