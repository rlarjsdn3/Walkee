//
//  GoalStepCountEntity+CoreDataProperties.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//
//

import Foundation
import CoreData


extension GoalStepCountEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalStepCountEntity> {
        return NSFetchRequest<GoalStepCountEntity>(entityName: "GoalStepCountEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var goalStepCount: Int32
    @NSManaged public var effectiveDate: Date
    @NSManaged public var userInfo: NSSet?

}

// MARK: Generated accessors for userInfo
extension GoalStepCountEntity {

    @objc(addUserInfoObject:)
    @NSManaged public func addToUserInfo(_ value: UserInfoEntity)

    @objc(removeUserInfoObject:)
    @NSManaged public func removeFromUserInfo(_ value: UserInfoEntity)

    @objc(addUserInfo:)
    @NSManaged public func addToUserInfo(_ values: NSSet)

    @objc(removeUserInfo:)
    @NSManaged public func removeFromUserInfo(_ values: NSSet)

}

extension GoalStepCountEntity : Identifiable {

}
