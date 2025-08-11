//
//  AlanActivitySummaryCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import HealthKit

final class AlanActivitySummaryCellViewModel {

    let anchorDate: Date
    // FIXME: ViewModel 간 의존을 제거할 수 있도록 구조 개선 검토 필요
    private let alanViewModel: AlanViewModel

    @Injected var healthService: (any HealthService)

    convenience init() { // 임시 코드
        self.init(alanViewModel: AlanViewModel())
    }

    ///
    init(
        anchorDate: Date = .now,
        alanViewModel: AlanViewModel
    ) {
        self.anchorDate = anchorDate
        self.alanViewModel = alanViewModel
    }

    ///
    func askAlanToSummarizeActivity() async throws -> String {
        guard await healthService.checkHasAnyReadPermission()
        else { throw HKError(.errorAuthorizationDenied) }

        let activeEnergyBurned: HealthKitData? = try? await healthService.fetchStatistics(for: .stepCount, from: anchorDate.startOfDay(), to: anchorDate.endOfDay(), options: .cumulativeSum, unit: .count())
        let distance: HealthKitData? = try? await healthService.fetchStatistics(for: .distanceWalkingRunning, from: anchorDate.startOfDay(), to: anchorDate.endOfDay(), options: .cumulativeSum, unit: .meterUnit(with: .kilo))
        let excerciseTime: HealthKitData? = try? await healthService.fetchStatistics(for: .appleExerciseTime, from: anchorDate.startOfDay(), to: anchorDate.endOfDay(), options: .cumulativeSum, unit: .minute())
        let stepCount: HealthKitData? = try? await healthService.fetchStatistics(for: .stepCount, from: anchorDate.startOfDay(), to: anchorDate.endOfDay(), options: .cumulativeSum, unit: .count())
        let stepLength: HealthKitData? = try? await healthService.fetchStatistics(for: .walkingStepLength, from: anchorDate.startOfDay(), to: anchorDate.endOfDay(), options: .mostRecent, unit: .meterUnit(with: .centi))
        let asymmetry: HealthKitData? = try? await healthService.fetchStatistics(for: .walkingAsymmetryPercentage, from: anchorDate.startOfDay(), to: anchorDate.endOfDay(), options: .mostRecent, unit: .percent())
        let walkingSpeed: HealthKitData? = try? await healthService.fetchStatistics(for: .walkingSpeed, from: anchorDate.startOfDay(), to: anchorDate.endOfDay(), options: .mostRecent, unit: .meter().unitDivided(by: .second()))
        let doubleSupport: HealthKitData? = try? await healthService.fetchStatistics(for: .walkingDoubleSupportPercentage, from: anchorDate.startOfDay(), to: anchorDate.endOfDay(), options: .mostRecent, unit: .percent())

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
