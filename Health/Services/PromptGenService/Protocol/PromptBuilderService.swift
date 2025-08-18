//
//  PromptBuilderService.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import Foundation

@MainActor
protocol PromptBuilderService {

    /// 프롬프트 문자열을 생성합니다.
    /// - Parameters:
    ///   - extraInstructions: 렌더링된 프롬프트 뒤에 덧붙일 추가 지시문(선행 개행은 자동 처리되지 않습니다).
    ///   - context: 외부에서 직접 구성해 전달할 컨텍스트. 전달되지 않으면 내부에서 사용자/헬스 데이터를 수집해 생성합니다.
    ///   - option: 템플릿 렌더링 옵션.
    /// - Returns: 생성된 프롬프트 문자열.
    /// - Throws: 사용자 정보/HealthKit 조회 중 발생한 오류를 전파합니다.
    func makePrompt(
        message extraInstructions: String,
        context: PromptContext?,
        option: PromptOption
    ) async throws -> String
}
