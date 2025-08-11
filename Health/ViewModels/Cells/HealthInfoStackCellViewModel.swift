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
        self.init(stackType: .activeEnergyBurned)
    }

    ///
    init(
        anchorDate: Date = .now,
        stackType: DashboardStackType
    ) {
        self.anchorDate = anchorDate
        self.stackType = stackType
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - startDate: <#startDate description#>
    ///   - endDate: <#endDate description#>
    /// - Returns: <#description#>
    func fetchStatisticsHKData(options: HKStatisticsOptions) async throws -> HealthKitData {
        try await healthService.fetchStatistics(
            for: stackType.quantityTypeIdentifier,
            from: anchorDate.startOfDay(),
            to: anchorDate.endOfDay(),
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
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents = .init(day: 1)
    ) async throws -> [HealthKitData] {
        try await healthService.fetchStatisticsCollection(
            for: stackType.quantityTypeIdentifier,
            from: anchorDate.startOfDay(),
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
