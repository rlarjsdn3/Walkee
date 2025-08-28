import CoreData
import Foundation
import HealthKit

/// HealthKit에서 걸음 수 데이터를 동기화하고 Core Data에 저장하는 서비스
///
/// HealthKit의 걸음 수 데이터를 앱의 Core Data 스택과 동기화하는 기능을 제공합니다.
protocol StepSyncService: Sendable {

    /// HealthKit에서 걸음 수 데이터를 가져와 Core Data에 동기화합니다.
    func syncSteps() async throws
}

/// `StepSyncService` 프로토콜의 기본 구현체
///
/// HealthKit에서 걸음 수 데이터를 가져와 Core Data에 저장하는 기능을 구현합니다.
/// 의존성 주입을 통해 `HealthService`를 주입받아 사용합니다.
final class DefaultStepSyncService: StepSyncService {

    @Injected private var healthService: HealthService

    /// HealthKit에서 걸음 수 데이터를 동기화합니다.
    ///
    /// 가장 이른 목표 걸음 수 날짜부터 현재까지의 데이터를 HealthKit에서 가져와 Core Data에 저장합니다.
    /// 기존 데이터가 있는 경우 업데이트하고, 없는 경우 새로 생성합니다.
    ///
    /// - Important: 백그라운드 스레드에서 Core Data 작업을 수행하므로 UI 업데이트는 메인 스레드에서 처리됩니다.
    func syncSteps() async throws {
        do {
            let endDate = Date()
            let startDate = try await fetchEarliestGoalStepDate() ?? endDate.startOfDay()

            // HealthKit에서 지정된 기간의 걸음 수 통계 데이터 가져오기
            let statistics = try await healthService.fetchStatisticsCollection(
                for: .stepCount,
                from: startDate,
                to: endDate,
                options: .cumulativeSum,
                interval: DateComponents(day: 1),
                unit: .count()
            )

            // Core Data에 데이터 저장 (백그라운드 스레드에서 실행)
            try await CoreDataStack.shared.performBackgroundTask { context in

                let statisticsMap = Dictionary(
                    uniqueKeysWithValues: statistics.map { ($0.startDate.startOfDay(), $0.value) }
                )

                var currentDate = startDate.startOfDay()
                let endDay = endDate.startOfDay()

                while currentDate <= endDay {
                    let stepCount = Int(statisticsMap[currentDate] ?? 0)
                    try self.upsertDailyStep(date: currentDate, stepCount: stepCount, in: context)
                    currentDate = currentDate.addingDays(1)!
                }

                try context.save()
            }

            // 동기화 완료 알림 발송 (메인 스레드에서 실행)
            await MainActor.run {
                NotificationCenter.default.post(name: .didSyncStepData, object: nil)
            }

            print("[StepSyncService] 동기화 완료: \(statistics.count)개의 날짜 처리됨")
        } catch {
            print("[StepSyncService] 동기화 실패: \(error.localizedDescription)")
            throw error
        }
    }
}

private extension DefaultStepSyncService {

    /// 가장 이른 목표 걸음 수 설정 날짜를 조회합니다.
    ///
    /// Core Data에서 `GoalStepCountEntity`의 가장 이른 `effectiveDate`를 찾아 반환합니다.
    /// 이 날짜는 걸음 수 동기화의 시작점으로 사용됩니다.
    ///
    /// - Returns: 가장 이른 목표 설정 날짜의 시작 시각, 데이터가 없는 경우 `nil`
    /// - Throws: Core Data 조회 중 발생한 오류
    func fetchEarliestGoalStepDate() async throws -> Date? {
        return try await withCheckedThrowingContinuation { continuation in
            CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
                do {
                    let request: NSFetchRequest<GoalStepCountEntity> = GoalStepCountEntity.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(key: "effectiveDate", ascending: true)]
                    request.fetchLimit = 1

                    let entity = try context.fetch(request).first
                    let date = entity?.effectiveDate?.startOfDay()
                    continuation.resume(returning: date)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 특정 날짜의 걸음 수 데이터를 업데이트하거나 새로 생성합니다.
    ///
    /// 지정된 날짜에 이미 `DailyStepEntity`가 존재하는 경우 걸음 수를 업데이트하고,
    /// 존재하지 않는 경우 새로운 엔터티를 생성합니다.
    ///
    /// - Parameters:
    ///   - date: 걸음 수를 기록할 날짜
    ///   - stepCount: 해당 날짜의 총 걸음 수
    ///   - context: Core Data 관리 객체 컨텍스트
    ///
    /// - Throws:
    ///   - Core Data 조회 또는 생성 중 발생한 오류
    ///   - 해당 날짜의 목표 걸음 수를 찾을 수 없는 경우
    nonisolated func upsertDailyStep(date: Date, stepCount: Int, in context: NSManagedObjectContext) throws {
		let startOfDay = date.startOfDay()

        let request: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)

        if let dailyStepEntity = try context.fetch(request).first {
            // 기존 데이터가 있는 경우: 걸음 수만 업데이트
            dailyStepEntity.stepCount = Int32(stepCount)
        } else {
            // 기존 데이터가 없는 경우: 새로운 엔터티 생성
            let dailyStepEntity = DailyStepEntity(context: context)
            dailyStepEntity.id = UUID()
            dailyStepEntity.date = startOfDay
            dailyStepEntity.stepCount = Int32(stepCount)

            let goalStepEntity = try fetchLatestGoalStep(on: startOfDay, in: context)
            dailyStepEntity.goalStepCount = goalStepEntity.goalStepCount
        }
    }

    /// 특정 날짜에 유효한 최신 목표 걸음 수를 조회합니다.
    ///
    /// 지정된 날짜 이전 또는 당일에 설정된 목표 걸음 수 중 가장 최근의 것을 반환합니다.
    /// 목표 걸음 수는 설정된 날짜부터 새로운 설정이 있을 때까지 유효합니다.
    ///
    /// - Parameters:
    ///   - date: 기준이 되는 날짜
    ///   - context: Core Data 관리 객체 컨텍스트
    ///
    /// - Returns: 해당 날짜에 유효한 목표 걸음 수 엔터티
    ///
    /// - Throws:
    ///   - Core Data 조회 중 발생한 오류
    ///   - 해당 날짜에 유효한 목표 걸음 수가 없는 경우 404 오류
    nonisolated func fetchLatestGoalStep(on date: Date, in context: NSManagedObjectContext) throws -> GoalStepCountEntity {
        let request: NSFetchRequest<GoalStepCountEntity> = GoalStepCountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "effectiveDate <= %@", date as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "effectiveDate", ascending: false)]
        request.fetchLimit = 1

        if let goalStepEntity = try context.fetch(request).first {
			return goalStepEntity
        } else {
            throw NSError(
                domain: "StepSyncService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "목표 걸음 수 데이터가 없습니다."]
            )
        }
    }
}
