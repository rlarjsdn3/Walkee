//
//  DefaultPromptTemplateGenerator.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import Foundation

final class DefaultPromptTemplateRenderService: PromptTemplateRenderService {

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
    ) -> String {
        
        return """
        다음은 한 사용자의 건강 데이터입니다. 일부 민감 정보는 비식별화 또는 마스킹 처리되었습니다.

        [메타데이터]
        - 날짜: \(context.date.formatted(using: .yyyymd))
        - 로케일: \(context.userLocale.identifier)

        [사용자 정보]
        - 성별: \(context.descriptor.gender)
        - 생년월일: \(context.descriptor.obfuscatedAge)
        - 체중: \(context.descriptor.obfuscatedWeight)
        - 신장: \(context.descriptor.obfuscatedHeight)
        - 질병: \(context.descriptor.diseases?.description ?? "정보 없음")
        - 목표 걷기 수: \(context.descriptor.goalStepCount)

        [금일 활동]
        - 오늘 걷기 수: \(context.descriptor.stepCount.map { "\($0)보" } ?? "정보 없음")
        - 걸은 거리: \(context.descriptor.distanceWalkingRunning.map { "\($0)km" } ?? "정보 없음")
        - 활동 에너지: \(context.descriptor.activeEnergyBurned.map { "\($0)kcal" } ?? "정보 없음")
        - 휴식 에너지: \(context.descriptor.basalEnergyBurned.map { "\($0)kcal" } ?? "정보 없음")
        - 보행 비대칭성: \(context.descriptor.walkingAsymmetryPercentage.map { "\($0 * 100.0)%" } ?? "정보 없음")
        - 보행 속도: \(context.descriptor.stepSpeed.map { "\($0)m/s" } ?? "정보 없음")
        - 보행 보폭: \(context.descriptor.stepLength.map { "\($0)cm" } ?? "정보 없음")
        - 이중 지지 시간: \(context.descriptor.doubleSupportPercentage.map { "\($0 * 100.0)%" } ?? "정보 없음")

        [최근 통계]
        - 이번 한 달간 걸음 수 차트: [\(context.descriptor.this1Months)]

        [요청 사항]
        \(option.description)
        
        """
    }
}
