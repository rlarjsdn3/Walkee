//
//  DefaultPromptBuilderService.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import HealthKit

final class DefaultPromptBuilderService: PromptBuilderService {
    
    @Injected private var userService: (any CoreDataUserService)
    @Injected private var healthService: (any HealthService)
    @Injected private var promptTemplateRenderService: (any PromptRenderService)

    /// 프롬프트 문자열을 생성합니다.
    /// - Parameters:
    ///   - extraInstructions: 렌더링된 프롬프트 뒤에 덧붙일 추가 지시문(선행 개행은 자동 처리되지 않습니다).
    ///   - context: 외부에서 직접 구성해 전달할 컨텍스트. 전달되지 않으면 내부에서 사용자/헬스 데이터를 수집해 생성합니다.
    ///   - option: 템플릿 렌더링 옵션.
    /// - Returns: 생성된 프롬프트 문자열.
    /// - Throws: 사용자 정보/HealthKit 조회 중 발생한 오류를 전파합니다.
    func makePrompt(
        message extraInstructions: String? = nil,
        context: PromptContext? = nil,
        option: PromptOption
    ) async throws -> String {
        var ctx: PromptContext

        if let context = context {
            ctx = context
        } else {
            // 사용자 나이 및 생년월일 정보 가져오기
            let userInfo = try userService.fetchUserInfo()
            let goalStepCount = latestGoalStepCount(from: userInfo) ?? 0

            // 사용자 건강 정보 가져오기
            let startOfMonth = Date.now.startOfMonth() ?? .now
            let endOfMonth = Date.now.endOfMonth() ?? .now
            async let stepCount = try fetchHKData(.stepCount)
            async let distanceWalkingRunning = try fetchHKData(.distanceWalkingRunning, unit: .meterUnit(with: .kilo))
            async let activeEnergyBurned = try fetchHKData(.activeEnergyBurned, unit: .kilocalorie())
            async let basalEnergyBurned = try fetchHKData(.basalEnergyBurned, unit: .kilocalorie())
            async let walkingSpeed = try fetchHKData(.walkingSpeed, options: .mostRecent, unit: .meter().unitDivided(by: .second()))
            async let stepLength = try fetchHKData(.walkingStepLength, options: .mostRecent, unit: .meterUnit(with: .centi))
            async let doubleSupportPercentage = try fetchHKData(.walkingDoubleSupportPercentage, options: .mostRecent, unit: .percent())
            async let asymmetryPercentage = try fetchHKData(.walkingAsymmetryPercentage, options: .mostRecent, unit: .percent())
            async let thisMonthStepCounts = try healthService.fetchStatisticsCollection(for: .stepCount, from: startOfMonth, to: endOfMonth, options: .cumulativeSum, interval: .init(day: 1), unit: .count())
            // TODO: - HealthService에서 가져오는 QuantityType과 HKUnit을 쉽게 일치시킬 방안 강구하기

            let descriptor = PromptDescriptor(
                age: Int(userInfo.age),
                gender: userInfo.gender ?? "unspecified",
                weight: userInfo.weight,
                height: userInfo.height,
                diseases: userInfo.diseases,
                goalStepCount: goalStepCount,
                stepCount: try await stepCount,
                distanceWalkingRunning: try await distanceWalkingRunning,
                activeEnergyBurned: try await activeEnergyBurned,
                basalEnergyBurned: try await basalEnergyBurned,
                stepLength: try await stepLength,
                stepSpeed: try await walkingSpeed,
                walkingAsymmetryPercentage: try await asymmetryPercentage,
                doubleSupportPercentage: try await doubleSupportPercentage,
                this1MonthStepCounts: try await thisMonthStepCounts
            )

            ctx = PromptContext(descriptor: descriptor)
        }

        var prompt = promptTemplateRenderService.render(with: ctx, option: option)
        prompt.append(extraInstructions ?? "")
        return prompt
    }
}

fileprivate extension DefaultPromptBuilderService {

    func fetchHKData(
        _ type: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions = .cumulativeSum,
        unit: HKUnit = .count()
    ) async throws -> Double {
        let startDate = Date.now.startOfDay()
        let endDate = Date.now.endOfDay()

        return try await healthService.fetchStatistics(
            for: type,
            from: startDate,
            to: endDate,
            options: options,
            unit: unit
        ).value
    }

    func latestGoalStepCount(from userInfo: UserInfoEntity) -> Int? {
        guard let set = userInfo.goalStepCount as? Set<GoalStepCountEntity> else { return nil }

        // 유효 시작된 것만 필터 → 가장 늦은 effectiveDate를 선택
        let candidate = set
            .max {
                let l = $0.effectiveDate ?? .distantPast
                let r = $1.effectiveDate ?? .distantPast
                return l < r
            }

        return candidate.map { Int($0.goalStepCount) }
    }
}
