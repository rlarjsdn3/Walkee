//
//  DailyStepEntity+CoreDataProperties.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//
//

import Foundation
import CoreData

/// 사용자의 하루 걸음 수 데이터를 저장하는 Core Data 엔티티
///
/// - 특정 날짜(`date`)의 실제 걸음 수(`stepCount`)와 목표 걸음 수(`goalStepCount`)를 기록한다.
/// - 사용자(`UserInfoEntity`)와의 관계를 통해 여러 사용자와 연결될 수 있다.
extension DailyStepEntity {
    
    /// `DailyStepEntity`를 가져오기 위한 `NSFetchRequest`
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyStepEntity> {
        return NSFetchRequest<DailyStepEntity>(entityName: "DailyStepEntity")
    }

    /// 걸음 수가 기록된 날짜
    @NSManaged public var date: Date?
    
    /// 해당 날짜의 목표 걸음 수
    @NSManaged public var goalStepCount: Int32
    
    /// 고유 식별자 (UUID)
    @NSManaged public var id: UUID?
    
    /// 실제 측정된 걸음 수
    @NSManaged public var stepCount: Int32
    
    /// 이 걸음 데이터와 연결된 사용자(`UserInfoEntity`) 정보 (1:N 관계)
    @NSManaged public var userInfo: NSSet?
}

//  - Generated accessors for userInfo
extension DailyStepEntity {
    
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
extension DailyStepEntity : Identifiable {}
