//
//  AlanActivitySummaryCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import HealthKit

final class AlanActivitySummaryCellViewModel { // TODO: - HashableViewModel 공통 코드 작성하기

    // FIXME: ViewModel 간 의존을 제거할 수 있도록 구조 개선 검토 필요
    private let alanViewModel: AlanViewModel

    @Injected var healthService: (any HealthService)

    convenience init() { // 임시 코드
        self.init(alanViewModel: AlanViewModel())
    }

    init(alanViewModel: AlanViewModel) {
        self.alanViewModel = alanViewModel
    }

    /// <#Description#>
    /// - Parameters:
    ///   - startDate: <#startDate description#>
    ///   - endDate: <#endDate description#>
    /// - Returns: <#description#>
    func fetchStatisticsHKData(
        _ identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        unit: HKUnit
    ) async throws -> HealthKitData {
        try await healthService.fetchStatistics(
            for: identifier,
            from: startDate,
            to: endDate,
            options: options,
            unit: unit
        )
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - activeEnergyBurned: <#activeEnergyBurned description#>
    ///   - distanceWalkingRunning: <#distanceWalkingRunning description#>
    ///   - exerciseTime: <#exerciseTime description#>
    ///   - stepCount: <#stepCount description#>
    ///   - walkingStepLength: <#walkingStepLength description#>
    ///   - walkingAsymmetryPercentage: <#walkingAsymmetryPercentage description#>
    ///   - walkingSpeed: <#walkingSpeed description#>
    ///   - walkdingDoubleSupportPercentage: <#walkdingDoubleSupportPercentage description#>
    /// - Returns: <#description#>
    func askAlanToSummarizeActivity(
        activeEnergyBurned: Double? = nil,
        distanceWalkingRunning: Double? = nil,
        exerciseTime: Double? = nil,
        stepCount: Double? = nil,
        walkingStepLength: Double? = nil,
        walkingAsymmetryPercentage: Double? = nil,
        walkingSpeed: Double? = nil,
        walkdingDoubleSupportPercentage: Double? = nil,
    ) async -> String {
        // TODO: - 받은 매개변수에 따라 프롬프트 작성하기
        var message: String = ""
        alanViewModel.didReceiveResponseText = { responseMsg in
            message = responseMsg
        }
        await alanViewModel.sendQuestion("")
        return message
    }

}

extension AlanActivitySummaryCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    nonisolated static func == (lhs: AlanActivitySummaryCellViewModel, rhs: AlanActivitySummaryCellViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
