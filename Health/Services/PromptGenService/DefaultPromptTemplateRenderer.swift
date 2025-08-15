//
//  DefaultPromptTemplateGenerator.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import Foundation

final class DefaultPromptTemplateRenderer: PromptTemplateRenderer {
    
    ///
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
        - 성별: \(context.user.gender)
        - 생년월일: \(context.user.obfuscatedAge)
        - 체중: \(context.health.obfuscatedWeight)
        - 신장: \(context.health.obfuscatedHeight)
        - 질병: \(context.health.diseases?.description ?? "정보 없음")

        [금일 활동]
        - 오늘 걷기 수: \(context.health.stepCount.map { "\($0)보" } ?? "정보 없음")
        - 걸은 거리: \(context.health.distanceWalkingRunning.map { "\($0)km" } ?? "정보 없음")
        - 활동 에너지: \(context.health.activeEnergyBurned.map { "\($0)kcal" } ?? "정보 없음")
        - 휴식 에너지: \(context.health.basalEnergyBurned.map { "\($0)kcal" } ?? "정보 없음")
        - 보행 비대칭성: \(context.health.walkingAsymmetryPercentage.map { "\($0 * 100.0)%" } ?? "정보 없음")
        - 보행 속도: \(context.health.walkingSpeed.map { "\($0)m/s" } ?? "정보 없음")
        - 보행 보폭: \(context.health.stepLength.map { "\($0)cm" } ?? "정보 없음")
        - 이중 지지 시간: \(context.health.doubleSupportPercentage.map { "\($0 * 100.0)%" } ?? "정보 없음")

        [최근 통계]
        - 지난 7(또는 14)일간 걸음 수 차트: [\(context.health.last7Days)]
        - 지난 6(또는 12)개월간 걸음 수 차트: [\(context.health.last12Months)]

        [요청 사항]
        \(option.description)
        
        """
    }
}
