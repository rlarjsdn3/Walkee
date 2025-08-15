//
//  PromptTemplateRenderer.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import Foundation

@MainActor
protocol PromptTemplateRenderService {
    
    /// 주어진 컨텍스트와 옵션을 기반으로 프롬프트 문자열을 생성합니다.
    /// - Parameters:
    ///   - context: 프롬프트에 삽입할 사용자·건강 데이터 및 메타 정보를 포함한 컨텍스트입니다.
    ///   - option: 프롬프트 요청 사항을 설명하는 옵션입니다.
    /// - Returns: 사용자 건강 데이터, 최근 통계, 요청 사항이 포함된 완성된 프롬프트 문자열입니다.
    /// - Note:
    ///   - 일부 민감 정보(나이, 체중, 신장 등)는 비식별화 또는 마스킹 처리된 값이 사용됩니다.
    ///   - `context.descriptor`의 각 속성 값이 없을 경우 `"정보 없음"`으로 대체됩니다.
    ///   - 날짜와 로케일은 `context.date`와 `context.userLocale`에서 포맷팅되어 출력됩니다.
    func render(
        with context: PromptContext,
        option: PromptOption
    ) -> String
}


