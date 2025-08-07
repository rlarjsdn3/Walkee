//
//  DailyStepViewModel.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//

import Foundation
import CoreData

final class DailyStepViewModel: ObservableObject {
    private let context: NSManagedObjectContext

    @Published var dailySteps: [DailyStepEntity] = []
    @Published var errorMessage: String?

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchAllDailySteps()
    }

    //전체 DailyStepEntity 목록 불러오기
    func fetchAllDailySteps() {
        let request: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyStepEntity.date, ascending: false)]

        do {
            dailySteps = try context.fetch(request)
        } catch {
            errorMessage = "Daily Steps 불러오기 실패: \(error.localizedDescription)"
        }
    }

    //특정 id로 DailyStepEntity 가져오기
    func fetchDailyStep(by id: UUID) -> DailyStepEntity? {
        let request: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            errorMessage = "특정 Daily Step 불러오기 실패: \(error.localizedDescription)"
            return nil
        }
    }

    //새 DailyStepEntity 저장 또는 기존 업데이트
    func saveDailyStep(id: UUID? = nil,
                       date: Date,
                       stepCount: Int32,
                       goalStepCount: Int32) {
        let entity: DailyStepEntity
        if let id = id, let existing = fetchDailyStep(by: id) {
            entity = existing
        } else {
            entity = DailyStepEntity(context: context)
            entity.id = UUID()
        }

        entity.date = date
        entity.stepCount = stepCount
        entity.goalStepCount = goalStepCount

        do {
            try context.save()
            fetchAllDailySteps()
        } catch {
            errorMessage = "Daily Step 저장 실패: \(error.localizedDescription)"
        }
    }

    //삭제
    func deleteDailyStep(_ dailyStep: DailyStepEntity) {
        context.delete(dailyStep)
        do {
            try context.save()
            fetchAllDailySteps()
        } catch {
            errorMessage = "삭제 실패: \(error.localizedDescription)"
        }
    }
}
