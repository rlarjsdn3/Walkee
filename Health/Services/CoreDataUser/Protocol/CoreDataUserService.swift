//
//  CoreDataUserService.swift
//  Health
//
//  Created by 김건우 on 8/14/25.
//

import Foundation

@MainActor
protocol CoreDataUserService {

    /// 새로운 사용자 정보를 Core Data에 생성합니다.
    /// - Parameters:
    ///   - id: 사용자의 고유 식별자(UUID). 기본값은 새로 생성됩니다.
    ///   - age: 나이(정수).
    ///   - gender: 성별(문자열).
    ///   - height: 키(센티미터 단위, Double).
    ///   - weight: 몸무게(킬로그램 단위, Double).
    ///   - diseases: 사용자가 가지고 있는 질병 목록(옵션).
    ///   - date: 생성 시각. 기본값은 현재 시간(`.now`)입니다.
    /// - Throws: Core Data 생성 작업 실패 시 오류를 던집니다.
    func createUserInfo(
        id: UUID,
        age: Int,
        gender: String,
        height: Double,
        weight: Double,
        diseases: [Disease]?,
        createdAt date: Date
    ) async throws

    /// 저장된 사용자 정보를 하나 가져옵니다.
    /// - Returns: `UserInfoEntity` 객체.
    /// - Throws: 저장된 사용자가 없거나, 읽기 작업이 실패한 경우 오류를 던집니다.
    func fetchUserInfo() throws -> UserInfoEntity

    /// 저장된 사용자 정보를 수정합니다.
    /// - Parameters:
    ///   - age: 변경할 나이(옵션).
    ///   - gender: 변경할 성별(옵션).
    ///   - height: 변경할 키(옵션).
    ///   - weight: 변경할 몸무게(옵션).
    ///   - diseases: 변경할 질병 목록(옵션).
    /// - Throws: 업데이트 실패 시 오류를 던집니다.
    func updateUserInfo(
        age: Int?,
        gender: String?,
        height: Double?,
        weight: Double?,
        diseases: [Disease]?
    ) async throws

    /// 저장된 사용자 정보를 삭제합니다.
    /// - Throws: 삭제 작업 실패 시 오류를 던집니다.
    func deleteUserInfo() async throws
}
