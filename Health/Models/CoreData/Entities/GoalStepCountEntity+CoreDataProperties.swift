//
//  GoalStepCountEntity+CoreDataProperties.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//
//

import Foundation
import CoreData

/// 사용자의 목표 걸음 수 정보를 저장하는 Core Data 엔티티
///
/// - 특정 날짜(`effectiveDate`)에 대한 목표 걸음 수(`goalStepCount`)를 기록한다.
/// - 사용자(`UserInfoEntity`)와의 관계를 통해 여러 사용자 데이터를 연결할 수 있다.
extension GoalStepCountEntity {
    
    /// `GoalStepCountEntity`를 가져오기 위한 `NSFetchRequest`
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalStepCountEntity> {
        return NSFetchRequest<GoalStepCountEntity>(entityName: "GoalStepCountEntity")
    }

    /// 목표 걸음 수가 적용되는 날짜
    ///
    /// - 특정 날짜부터 해당 목표 걸음 수가 유효함을 의미한다.
    @NSManaged public var effectiveDate: Date?
    
    /// 설정된 목표 걸음 수 (단위: 걸음 수)
    @NSManaged public var goalStepCount: Int32
    
    /// 고유 식별자 (UUID)
    @NSManaged public var id: UUID?
    
    /// 이 목표 걸음 수와 연결된 사용자(`UserInfoEntity`) 정보 (1:N 관계)
    @NSManaged public var userInfo: NSSet?
}

// - Generated accessors for userInfo
extension GoalStepCountEntity {
    
    /// `userInfo` 관계에 새로운 `UserInfoEntity`를 추가
    @objc(addUserInfoObject:)
    @NSManaged public func addToUserInfo(_ value: UserInfoEntity)

    /// `userInfo` 관계에서 특정 `UserInfoEntity`를 제거
    @objc(removeUserInfoObject:)
    @NSManaged public func removeFromUserInfo(_ value: UserInfoEntity)

    /// 여러 개의 `UserInfoEntity`를 `userInfo` 관계에 추가
    @objc(addUserInfo:)
    @NSManaged public func addToUserInfo(_ values: NSSet)

    /// 여러 개의 `UserInfoEntity`를 `userInfo` 관계에서 제거
    @objc(removeUserInfo:)
    @NSManaged public func removeFromUserInfo(_ values: NSSet)
}

// - Identifiable 프로토콜 채택
extension GoalStepCountEntity : Identifiable {}
