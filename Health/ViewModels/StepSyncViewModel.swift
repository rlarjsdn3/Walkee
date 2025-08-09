import HealthKit

/// `StepSyncViewModel`은 HealthKit 데이터를 기반으로 누락된 일자들의 걸음 수를 CoreData에 반영하는 역할을 담당합니다.
///
/// 앱이 실행되거나 포그라운드로 전환될 때 `DailyStepEntity`에 저장되지 않은 날짜들을 찾아
/// HealthKit에서 걸음 수를 가져와 저장합니다. 의존성 주입을 통해 필요한 서비스들을 사용합니다.
///
/// - Note: HealthKit 권한이 필요하며, 권한이 없을 경우 동기화가 실패할 수 있습니다.
@MainActor
final class StepSyncViewModel: ObservableObject {

    @Injected private var healthService: HealthService
    @Injected private var dailyStepVM: DailyStepViewModel
    @Injected private var goalStepCountVM: GoalStepCountViewModel

    @Published var syncCompleted: Bool = false
    @Published var errorMessage: String?

    func syncDailySteps() async {
        let today = Date().startOfDay()
        let missingDates = dailyStepVM.fetchMissingDates(until: today)

        guard !missingDates.isEmpty else {
            syncCompleted = true
            return
        }

        var successCount = 0
        var failureCount = 0
        var errors: [String] = []

        await withTaskGroup(of: Bool.self) { group in
            for date in missingDates {
                group.addTask { @Sendable in
                    do {
                        try await self.syncStep(for: date)
                        return true
                    } catch {
                        await MainActor.run {
                            errors.append("\(date.formatted(using: .m_d)): \(error.localizedDescription)")
                        }
                        return false
                    }
                }
            }

            for await result in group {
                if result {
                    successCount += 1
                } else {
                    failureCount += 1
                }
            }
        }

        syncCompleted = true
        errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")

#if DEBUG
        print("[동기화 완료] 성공: \(successCount)개, 실패: \(failureCount)개")
        errors.forEach { print($0) }
#endif
    }

    private func syncStep(for date: Date) async throws {
        let normalizedDate = date.startOfDay()
        let endDate = normalizedDate.endOfDay()

        let result = try await healthService.fetchStatistics(
            for: .stepCount,
            from: normalizedDate,
            to: endDate,
            options: .cumulativeSum,
            unit: .count()
        )

        let stepCount = Int32(result.value.rounded())
        let goal = goalStepCountVM.goalStepCount(for: normalizedDate) ?? 10_000

        await MainActor.run {
            dailyStepVM.upsertDailyStep(for: normalizedDate, stepCount: stepCount, goalStepCount: goal)

#if DEBUG
            print("[동기화] \(normalizedDate.formatted(using: .m_d)) | 걸음 수: \(stepCount) | 목표: \(goal)")
#endif
        }
    }
}
