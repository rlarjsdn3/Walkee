//
//  DailyStepViewModel.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//


import Foundation
import CoreData

final class DailyStepViewModel {
    
    private let context: NSManagedObjectContext
    
    var dailyStepEntity: DailyStepEntity?
    var errorMessage: String?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchDailyStep(by id: UUID) {
        let request: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            dailyStepEntity = results.first
        } catch {
            errorMessage = "Fetch 실패: \(error.localizedDescription)"
        }
    }
    
    func saveDailyStep(id: UUID = UUID(),
                       date: Date,
                       stepCount: Int32,
                       goalStepCount: Int32) {
        
        let entity = dailyStepEntity ?? DailyStepEntity(context: context)
        
        entity.id = id
        entity.date = date
        entity.stepCount = stepCount
        entity.goalStepCount = goalStepCount
        
        do {
            try context.save()
            dailyStepEntity = entity
        } catch {
            errorMessage = "저장 실패: \(error.localizedDescription)"
        }
    }
    
    func addUserInfo(_ userInfo: UserInfoEntity) {
        dailyStepEntity?.addToUserInfo(userInfo)
        saveContext()
    }
    
    func removeUserInfo(_ userInfo: UserInfoEntity) {
        dailyStepEntity?.removeFromUserInfo(userInfo)
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
