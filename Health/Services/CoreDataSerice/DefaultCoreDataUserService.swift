//
//  DefaultCoreDataUserService.swift
//  Health
//
//  Created by 김건우 on 8/14/25.
//

import Foundation

/// `DefaultCoreDataUserService`
///
/// Core Data를 사용하여 사용자 정보를 생성, 조회, 수정, 삭제하는 서비스 구현체입니다.
/// 이 클래스는 `CoreDataUserService` 프로토콜을 준수하며,
/// 내부적으로 `CoreDataStack`을 활용해 `UserInfoEntity` 엔티티를 관리합니다.
final class DefaultCoreDataUserService: CoreDataUserService {

    private let coreDataStack: CoreDataStack

    /// 지정 이니셜라이저입니다.
    /// - Parameter coreDataStack: Core Data 작업에 사용할 `CoreDataStack` 객체입니다. 기본값은 `.shared`입니다.
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    /// 새로운 사용자 정보를 Core Data에 생성합니다.
    /// - Parameters:
    ///   - id: 사용자의 고유 식별자(UUID). 기본값은 새로 생성됩니다.
    ///   - age: 나이(정수).
    ///   - gender: 성별(문자열).
    ///   - height: 키(센티미터 단위, Double).
    ///   - weight: 몸무게(킬로그램 단위, Double).
    ///   - diseases: 사용자가 가지고 있는 질병 목록(옵션).
    ///   - date: 생성 시각. 기본값은 현재 시간(`.now`)입니다.
    /// - Throws: Core Data에 생성 작업 실패 시 `CoreDataError.createError`를 던집니다.
    func createUserInfo(
        id: UUID = UUID(),
        age: Int,
        gender: String,
        height: Double,
        weight: Double,
        diseases: [Disease]?,
        createdAt date: Date = .now
    ) async throws {
        await coreDataStack.performBackgroundTask { context in
            let userEntity = UserInfoEntity(context: context)
            userEntity.id = id
            userEntity.age = Int16(age)
            userEntity.gender = gender
            userEntity.height = height
            userEntity.weight = weight
            userEntity.createdAt = date
            userEntity.diseases = diseases
        }
    }

    /// 저장된 사용자 정보를 하나 가져옵니다.
    /// - Returns: `UserInfoEntity` 객체.
    /// - Throws: 저장된 사용자가 없거나, 읽기 작업이 실패한 경우 `CoreDataError.readError`를 던집니다.
    func fetchUserInfo() throws -> UserInfoEntity {
        do {
            let users: [UserInfoEntity] = try coreDataStack.fetch()
            guard let user = users.first else { throw CoreDataError.readError }
            return user
        } catch {
            throw CoreDataError.readError
        }
    }

    /// 저장된 사용자 정보를 수정합니다.
    /// - Parameters:
    ///   - age: 변경할 나이(옵션).
    ///   - gender: 변경할 성별(옵션).
    ///   - height: 변경할 키(옵션).
    ///   - weight: 변경할 몸무게(옵션).
    ///   - diseases: 변경할 질병 목록(옵션).
    /// - Throws: 업데이트 실패 시 `CoreDataError.updateError`를 던집니다.
    func updateUserInfo(
        age: Int? = nil,
        gender: String? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        diseases: [Disease]? = nil
    ) async throws {
        let objectID = try fetchUserInfo().objectID
        
        try await coreDataStack.performBackgroundTask { context in
            let userEntity = try context.existingObject(with: objectID) as! UserInfoEntity
            if let age { userEntity.age = Int16(age) }
            if let gender { userEntity.gender = gender }
            if let height { userEntity.height = height }
            if let weight { userEntity.weight = weight }
            if let diseases { userEntity.diseases = diseases }
            if context.hasChanges { try context.save() }
        }
    }

    /// 저장된 사용자 정보를 삭제합니다.
    /// - Throws: 삭제 작업 실패 시 `CoreDataError.deleteError`를 던집니다.
    func deleteUserInfo() async throws {
        let objectID = try fetchUserInfo().objectID
        
        try await coreDataStack.performBackgroundTask { context in
            let userEntity = try context.existingObject(with: objectID) as! UserInfoEntity
            context.delete(userEntity)
            if context.hasChanges { try context.save() }
        }
    }

}
