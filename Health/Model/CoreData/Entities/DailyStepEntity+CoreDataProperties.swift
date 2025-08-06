//
//  DailyStepEntity+CoreDataProperties.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//
//

import Foundation
import CoreData


extension DailyStepEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyStepEntity> {
        return NSFetchRequest<DailyStepEntity>(entityName: "DailyStepEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var stepCount: Int32
    @NSManaged public var goalStepCount: Int32
    @NSManaged public var userInfo: UserInfoEntity?

}

// MARK: Generated accessors for DailyStep
extension DailyStepEntity {

    @objc(addUserInfoObject:)
    @NSManaged public func addToUserInfo(_ value: UserInfoEntity)

    @objc(removeUserInfoObject:)
    @NSManaged public func removeFromUserInfo(_ value: UserInfoEntity)

    @objc(addUserInfo:)
    @NSManaged public func addToUserInfo(_ values: NSSet)

    @objc(removeUserInfo:)
    @NSManaged public func removeFromUserInfo(_ values: NSSet)

}

extension DailyStepEntity : Identifiable {

}
