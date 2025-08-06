//
//  GoalStepCountViewModel.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//


import Foundation
import CoreData

final class GoalStepCountViewModel {
    
    private let context: NSManagedObjectContext
    
    var goalStepCountEntity: GoalStepCountEntity?
    var errorMessage: String?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchGoalStepCount(by id: UUID) {
        let request: NSFetchRequest<GoalStepCountEntity> = GoalStepCountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            goalStepCountEntity = results.first
        } catch {
            errorMessage = "Fetch 실패: \(error.localizedDescription)"
        }
    }
  
    func saveGoalStepCount(id: UUID = UUID(),
                           goalStepCount: Int32,
                           effectiveDate: Date) {
        
        let entity = goalStepCountEntity ?? GoalStepCountEntity(context: context)
        
        entity.id = id
        entity.goalStepCount = goalStepCount
        entity.effectiveDate = effectiveDate
        
        do {
            try context.save()
            goalStepCountEntity = entity
        } catch {
            errorMessage = "저장 실패: \(error.localizedDescription)"
        }
    }
    
    func addUserInfo(_ userInfo: UserInfoEntity) {
        goalStepCountEntity?.addToUserInfo(userInfo)
        saveContext()
    }
    
    func removeUserInfo(_ userInfo: UserInfoEntity) {
        goalStepCountEntity?.removeFromUserInfo(userInfo)
        saveContext()
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            errorMessage = "Context 저장 실패: \(error.localizedDescription)"
        }
    }
}
