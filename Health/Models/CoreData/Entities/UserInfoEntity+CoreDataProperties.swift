//
//  UserInfoEntity+CoreDataProperties.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//
//

import Foundation
import CoreData

/// 사용자 정보를 저장하는 Core Data 엔티티
///
/// - 나이, 성별, 키, 몸무게 등 신체 정보와
/// - 질병 정보(`disease`), 걸음 기록(`dailyStep`), 목표 걸음 수(`goalStepCount`)를 포함한다.
/// - Core Data 모델 `UserInfoEntity`와 매핑된다.
extension UserInfoEntity {
    
    /// `UserInfoEntity`를 가져오기 위한 `NSFetchRequest`
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserInfoEntity> {
        return NSFetchRequest<UserInfoEntity>(entityName: "UserInfoEntity")
    }

    /// 사용자 나이
    @NSManaged public var age: Int16
    
    /// 사용자 데이터가 생성된 시각
    @NSManaged public var createdAt: Date?
    
    /// 질병 정보를 JSON 문자열 형태로 저장 (내부 저장용)
    ///
    /// - 실제 사용 시에는 `diseases` 프로퍼티를 이용하는 것을 권장
    @NSManaged public var disease: String?
    
    /// 성별 ("male", "female" 등 문자열 형태)
    @NSManaged public var gender: String?
    
    /// 키 (단위: cm)
    @NSManaged public var height: Double
    
    /// 사용자 고유 ID
    @NSManaged public var id: UUID?
    
    /// 몸무게 (단위: kg)
    @NSManaged public var weight: Double
    
    /// 사용자의 하루 걸음 기록 (`DailyStepEntity`와 1:N 관계)
    @NSManaged public var dailyStep: NSSet?
    
    /// 사용자의 목표 걸음 기록 (`GoalStepCountEntity`와 1:N 관계)
    @NSManaged public var goalStepCount: NSSet?

    // - 편의 프로퍼티
    
    /// JSON 문자열(`disease`)과 연동되는 질병 목록
    ///
    /// - 내부적으로 `Disease` 배열을 JSON 문자열로 변환하여 Core Data에 저장한다.
    /// - 불러올 때는 JSON을 디코딩하여 `[Disease]` 배열로 반환한다.
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

// - Generated accessors for DailyStep
extension UserInfoEntity {
    
    /// `dailyStep` 관계에 새로운 `DailyStepEntity`를 추가
    @objc(addDailyStepObject:)
    @NSManaged public func addToDailyStep(_ value: DailyStepEntity)

    /// `dailyStep` 관계에서 특정 `DailyStepEntity`를 제거
    @objc(removeDailyStepObject:)
    @NSManaged public func removeFromDailyStep(_ value: DailyStepEntity)

    /// 여러 개의 `DailyStepEntity`를 `dailyStep` 관계에 추가
    @objc(addDailyStep:)
    @NSManaged public func addToDailyStep(_ values: NSSet)

    /// 여러 개의 `DailyStepEntity`를 `dailyStep` 관계에서 제거
    @objc(removeDailyStep:)
    @NSManaged public func removeFromDailyStep(_ values: NSSet)
}

// - Generated accessors for GoalStepCount
extension UserInfoEntity {
    
    /// `goalStepCount` 관계에 새로운 `GoalStepCountEntity`를 추가
    @objc(addGoalStepCountObject:)
    @NSManaged public func addToGoalStepCount(_ value: GoalStepCountEntity)

    /// `goalStepCount` 관계에서 특정 `GoalStepCountEntity`를 제거
    @objc(removeGoalStepCountObject:)
    @NSManaged public func removeFromGoalStepCount(_ value: GoalStepCountEntity)

    /// 여러 개의 `GoalStepCountEntity`를 `goalStepCount` 관계에 추가
    @objc(addGoalStepCount:)
    @NSManaged public func addToGoalStepCount(_ values: NSSet)

    /// 여러 개의 `GoalStepCountEntity`를 `goalStepCount` 관계에서 제거
    @objc(removeGoalStepCount:)
    @NSManaged public func removeFromGoalStepCount(_ values: NSSet)
}

/// - Identifiable 프로토콜 채택
extension UserInfoEntity : Identifiable {
    
}
