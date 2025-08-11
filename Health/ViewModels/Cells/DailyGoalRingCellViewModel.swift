//
//  DailyGoalRingCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Foundation

final class DailyGoalRingCellViewModel: @unchecked Sendable {

    let goalStepCount: Double
    let currentStepCount: Double

    convenience init() { // TODO: - 생성자 코드 삭제하기
        self.init(goalStepCount: 1000, currentStepCount: 500)
    }

    init(goalStepCount: Int, currentStepCount: Int) {
        self.goalStepCount = Double(goalStepCount)
        self.currentStepCount = Double(currentStepCount)
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
