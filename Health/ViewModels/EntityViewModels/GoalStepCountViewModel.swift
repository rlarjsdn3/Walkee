//
//  GoalStepCountViewModel.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//

import Foundation
import CoreData

final class GoalStepCountViewModel: ObservableObject {
    private let context: NSManagedObjectContext

    @Published var goalStepCounts: [GoalStepCountEntity] = []
    @Published var errorMessage: String?

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchAllGoalStepCounts()
    }

    //전체 GoalStepCount 목록 조회 (최신순)
    func fetchAllGoalStepCounts() {
        let request: NSFetchRequest<GoalStepCountEntity> = GoalStepCountEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalStepCountEntity.effectiveDate, ascending: false)]

        do {
            goalStepCounts = try context.fetch(request)
        } catch {
            errorMessage = "GoalStepCount 불러오기 실패: \(error.localizedDescription)"
        }
    }

    //특정 ID로 GoalStepCount 조회
    func fetchGoalStepCount(by id: UUID) -> GoalStepCountEntity? {
        let request: NSFetchRequest<GoalStepCountEntity> = GoalStepCountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            errorMessage = "GoalStepCount 조회 실패: \(error.localizedDescription)"
            return nil
        }
    }

    //GoalStepCount 저장 또는 업데이트
    func saveGoalStepCount(id: UUID? = nil,
                           goalStepCount: Int32,
                           effectiveDate: Date) {
        let entity: GoalStepCountEntity
        if let id = id, let existing = fetchGoalStepCount(by: id) {
            entity = existing
        } else {
            entity = GoalStepCountEntity(context: context)
            entity.id = UUID()
        }

        entity.goalStepCount = goalStepCount
        entity.effectiveDate = effectiveDate

        do {
            try context.save()
            fetchAllGoalStepCounts()
        } catch {
            errorMessage = "GoalStepCount 저장 실패: \(error.localizedDescription)"
        }
    }

    //삭제
    func deleteGoalStepCount(_ goalStepCountEntity: GoalStepCountEntity) {
        context.delete(goalStepCountEntity)
        do {
            try context.save()
            fetchAllGoalStepCounts()
        } catch {
            errorMessage = "삭제 실패: \(error.localizedDescription)"
        }
    }
}
