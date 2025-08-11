//
//  DailyGoalRingCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Foundation

final class DailyGoalRingCellViewModel: @unchecked Sendable {

    let anchorDate: Date
    let goalStepCount: Double

    @Injected private var healthService: (any HealthService)

    convenience init() { // TODO: - 생성자 코드 삭제하기
        self.init(goalStepCount: 1000)
    }

    init(
        anchorDate: Date = .now,
        goalStepCount: Int
    ) {
        self.anchorDate = anchorDate
        self.goalStepCount = Double(goalStepCount)
    }

    func fetchStatisticsHKData() async throws -> HealthKitData {
        try await healthService.fetchStatistics(
            for: .stepCount,
            from: anchorDate.startOfDay(),
            to: anchorDate.startOfDay().addingDays(1) ?? .now,
            options: .cumulativeSum,
            unit: .count()
        )
    }
}

extension DailyGoalRingCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    nonisolated static func == (lhs: DailyGoalRingCellViewModel, rhs: DailyGoalRingCellViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
