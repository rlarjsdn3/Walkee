//
//  HealthInfoCardCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import HealthKit

final class HealthInfoCardCellViewModel {

    let cardType: DashboardCardType

    @Injected var healthService: (any HealthService)

    convenience init() { // 임시 코드
        self.init(.walkingStepLength)
    }

    ///
    init(_ cardType: DashboardCardType) {
        self.cardType = cardType
    }

    /// <#Description#>
    /// - Parameters:
    ///   - startDate: <#startDate description#>
    ///   - endDate: <#endDate description#>
    /// - Returns: <#description#>
    func fetchStatisticsHealthKitData(
        from startDate: Date = .now.startOfDay(),
        to endDate: Date = .now.endOfDay(),
        options: HKStatisticsOptions
    ) async throws -> HealthKitData {
        try await healthService.fetchStatistics(
            for: cardType.quantityTypeIdentifier,
            from: startDate,
            to: endDate,
            options: options,
            unit: cardType.unit
        )
    }

    ///
    func evaluateStatus(_ value: Double, age: Int) -> DashboardCardType.GaitStatus {
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
