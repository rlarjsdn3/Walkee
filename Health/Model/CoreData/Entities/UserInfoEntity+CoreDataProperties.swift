//
//  UserInfoEntity+CoreDataProperties.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//
//

import Foundation
import CoreData

extension UserInfoEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserInfoEntity> {
        return NSFetchRequest<UserInfoEntity>(entityName: "UserInfoEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var username: String
    @NSManaged public var age: Int16
    @NSManaged public var gender: String
    @NSManaged public var weight: Double
    @NSManaged public var height: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var disease: String?
    @NSManaged public var goalStepCount: NSSet?
    @NSManaged public var dailyStep: NSSet?

    
    var diseases: [Disease]? {
        get {
            guard let diseaseString = disease,
                  let data = diseaseString.data(using: .utf8) else {
                return nil
            }
            return try? JSONDecoder().decode([Disease].self, from: data)
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: data, encoding: .utf8) {
                disease = jsonString
            } else {
                disease = nil
            }
        }
    }
}

// MARK: Generated accessors for userInfo
extension UserInfoEntity {

    @objc(addGoalStepCountObject:)
    @NSManaged public func addToGoalStepCount(_ value: GoalStepCountEntity)

    @objc(removeGoalStepCountObject:)
    @NSManaged public func removeFromGoalStepCount(_ value: GoalStepCountEntity)

    @objc(addGoalStepCount:)
    @NSManaged public func addToGoalStepCount(_ values: NSSet)

    @objc(removeGoalStepCount:)
    @NSManaged public func removeFromGoalStepCount(_ values: NSSet)
}

extension UserInfoEntity {

    @objc(addDailyStepObject:)
    @NSManaged public func addToDailyStep(_ value: DailyStepEntity)

    @objc(removeDailyStepObject:)
    @NSManaged public func removeFromDailyStep(_ value: DailyStepEntity)

    @objc(addDailyStep:)
    @NSManaged public func addToDailyStep(_ values: NSSet)

    @objc(removeDailyStep:)
    @NSManaged public func removeFromDailyStep(_ values: NSSet)
}

extension UserInfoEntity: Identifiable { }

/*

 disease 배열 사용방법
 
 let user = UserInfoEntity(context: context)

// 저장
user.diseases = [.arthritis, .fracture]

// 읽기
if let diseases = user.diseases {
    for disease in diseases {
        print("질병: \(disease.localizedName)")
    }
}
 
 */


