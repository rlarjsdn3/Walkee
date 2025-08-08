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

    let stackType: DashboardStackType

    ///
    var title: String? {
        stackType.title
    }

    ///
    var systemName: String {
        stackType.systemName
    }

    ///
    var unitString: String? {
        stackType.unit.unitString
    }

    @Injected var healthService: (any HealthService)

    convenience init() { // 임시 코드
        self.init(.activeEnergyBurned)
    }

    ///
    init(_ cardStack: DashboardStackType) {
        self.stackType = cardStack
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - startDate: <#startDate description#>
    ///   - endDate: <#endDate description#>
    /// - Returns: <#description#>
    func fetchStatisticsHKData(
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions
    ) async throws -> HealthKitData {
        try await healthService.fetchStatistics(
            for: stackType.quantityTypeIdentifier,
            from: startDate,
            to: endDate,
            options: options,
            unit: stackType.unit
        )
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - startDate: <#startDate description#>
    ///   - endDate: <#endDate description#>
    /// - Returns: <#description#>
    func fetchStatisticsCollectionHKData(
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents = .init(day: 1)
    ) async throws -> [HealthKitData] {
        try await healthService.fetchStatisticsCollection(
            for: stackType.quantityTypeIdentifier,
            from: startDate,
            to: endDate,
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
