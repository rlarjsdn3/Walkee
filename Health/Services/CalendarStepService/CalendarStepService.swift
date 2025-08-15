import CoreData
import Foundation

/// 달력의 각 날짜별 걸음 수 및 목표 걸음 수를 제공하는 서비스
///
/// - 이 서비스는 `DailyStepViewModel` 또는 `GoalStepCountViewModel`을 거치지 않고
///   **Core Data를 직접 조회**합니다.
/// - 이유:
///   1. **최신성 보장**: HealthKit 동기화 직후 또는 더미 데이터 삽입 직후에도 즉시 UI 반영 가능
///   2. **초기화 타이밍 문제 회피**: ViewModel은 init 시점에 한 번만 fetch를 실행하기 때문에,
///      데이터 삽입 이후 갱신이 반영되지 않는 경우가 있었음
///   3. **메모리 효율성**: 달력은 개별 날짜 단위 조회만 필요하므로, 전체 데이터를 캐싱할 필요가 없음
@MainActor
protocol CalendarStepService {

    func steps(for date: Date) -> (current: Int?, goal: Int?)
}

final class DefaultCalendarStepService: CalendarStepService {

    func steps(for date: Date) -> (current: Int?, goal: Int?) {
        let context = CoreDataStack.shared.viewContext
        let (startOfDay, endOfDay) = date.rangeOfDay()

        // DailyStepEntity 조회 (해당 날짜의 기록이 있을 경우)
        let dailyRequest: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        dailyRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)

        if let daily = try? context.fetch(dailyRequest).first {
            return (Int(daily.stepCount), Int(daily.goalStepCount))
        }

        // GoalStepCountEntity 조회 (해당 날짜에 걸음 수 기록이 없을 경우)
        let goalRequest: NSFetchRequest<GoalStepCountEntity> = GoalStepCountEntity.fetchRequest()
        goalRequest.predicate = NSPredicate(format: "effectiveDate <= %@", startOfDay as NSDate)
        goalRequest.sortDescriptors = [NSSortDescriptor(key: "effectiveDate", ascending: false)]

        if let goal = try? context.fetch(goalRequest).first {
            return (nil, Int(goal.goalStepCount))
        }

        return (nil, nil)
    }
}
