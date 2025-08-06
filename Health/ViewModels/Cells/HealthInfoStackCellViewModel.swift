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

    let cardStack: DashboardCardStack

    ///
    var title: String? {
        cardStack.title
    }

    ///
    var systemName: String {
        cardStack.systemName
    }

    ///
    var unitString: String? {
        cardStack.unitString
    }

    @Injected var healthService: (any HealthService)

    convenience init() {
        self.init(cardStack: .activeEnergyBurned)
    }

    ///
    init(cardStack: DashboardCardStack) {
        self.cardStack = cardStack
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - startDate: <#startDate description#>
    ///   - endDate: <#endDate description#>
    /// - Returns: <#description#>
    func fetchStatisticsData(
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions
    ) async throws -> HealthKitData {
        try await healthService.fetchStatistics(
            for: cardStack.quantityTypeIdentifier,
            from: startDate,
            to: endDate,
            options: options,
            unit: cardStack.unit
        )
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - startDate: <#startDate description#>
    ///   - endDate: <#endDate description#>
    /// - Returns: <#description#>
    func fetchStatisticsCollectionData(
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents = .init(day: 1)
    ) async throws -> [HealthKitData] {
        try await healthService.fetchStatisticsCollection(
            for: cardStack.quantityTypeIdentifier,
            from: startDate,
            to: endDate,
            options: options,
            interval: intervalComponents,
            unit: cardStack.unit
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
