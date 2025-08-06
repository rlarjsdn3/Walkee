//
//  UserInfoViewModel.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//


import Foundation
import CoreData

final class UserInfoViewModel {
    
    private let context: NSManagedObjectContext
    var userInfo: UserInfoEntity?
    var errorMessage: String?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchUserInfo(id: UUID) {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            userInfo = results.first
        } catch {
            errorMessage = "Fetch 실패: \(error.localizedDescription)"
        }
    }
    
    //변경하라는의미는 아니지만, 파라미터에서 불러오는게 너무많아보인다.
    
    func saveUserInfo(username: String,
                      age: Int16,
                      gender: String,
                      weight: Double,
                      height: Double,
                      diseases: [Disease]) {
        
        let entity = userInfo ?? UserInfoEntity(context: context)
        
        entity.username = username
        entity.age = age
        entity.gender = gender
        entity.weight = weight
        entity.height = height
        entity.diseases = diseases
        
        if entity.createdAt == nil {
            entity.createdAt = Date()
        }
        
        do {
            try context.save()
            userInfo = entity
        } catch {
            errorMessage = "저장 실패: \(error.localizedDescription)"
        }
    }
}
