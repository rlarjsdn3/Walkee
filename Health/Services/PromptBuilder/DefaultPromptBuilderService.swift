//
//  DefaultPromptBuilderService.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import HealthKit

final class DefaultPromptBuilderService: PromptBuilderService {

    private let goalStepViewModel = GoalStepCountViewModel(context: CoreDataStack.shared.viewContext)
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
            let goalStepCount = latestGoalStepCount()

            // 사용자 건강 정보 가져오기
            let startOfMonth = Date.now.startOfMonth() ?? .now
            let endOfMonth = Date.now.endOfMonth() ?? .now
            async let stepCount = try? fetchHKData(.stepCount)
            async let distanceWalkingRunning = try? fetchHKData(.distanceWalkingRunning, unit: .meterUnit(with: .kilo))
            async let activeEnergyBurned = try? fetchHKData(.activeEnergyBurned, unit: .kilocalorie())
            async let basalEnergyBurned = try? fetchHKData(.basalEnergyBurned, unit: .kilocalorie())
            async let walkingSpeed = try? fetchHKData(.walkingSpeed, options: .discreteAverage, unit: .meter().unitDivided(by: .second()))
            async let stepLength = try? fetchHKData(.walkingStepLength, options: .discreteAverage, unit: .meterUnit(with: .centi))
            async let doubleSupportPercentage = try? fetchHKData(.walkingDoubleSupportPercentage, options: .discreteAverage, unit: .percent())
            async let asymmetryPercentage = try? fetchHKData(.walkingAsymmetryPercentage, options: .discreteAverage, unit: .percent())
            async let thisMonthStepCounts = try? healthService.fetchStatisticsCollection(for: .stepCount, from: startOfMonth, to: endOfMonth, options: .cumulativeSum, interval: .init(day: 1), unit: .count())

            let descriptor = PromptDescriptor(
                age: Int(userInfo.age),
                gender: userInfo.gender ?? "unspecified",
                weight: userInfo.weight,
                height: userInfo.height,
                diseases: userInfo.diseases,
                goalStepCount: goalStepCount,
                stepCount: await stepCount,
                distanceWalkingRunning: await distanceWalkingRunning,
                activeEnergyBurned: await activeEnergyBurned,
                basalEnergyBurned: await basalEnergyBurned,
                stepLength: await stepLength,
                stepSpeed: await walkingSpeed,
                walkingAsymmetryPercentage: await asymmetryPercentage,
                doubleSupportPercentage: await doubleSupportPercentage,
                this1MonthStepCounts: await thisMonthStepCounts
            )

            ctx = PromptContext(descriptor: descriptor)
        }

        var prompt = promptTemplateRenderService.render(with: ctx, option: option)
        prompt.append(extraInstructions ?? "")
        print("생성된 프롬프트:", prompt)
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

    func latestGoalStepCount(for date: Date = .distantFuture) -> Int {
        guard let goalStepCount = goalStepViewModel.goalStepCount(for: date)
        else { fatalError("🔴 목표 걸음 수를 로드할 수 없음 (PromptBuilderSevice)") }
        return Int(goalStepCount)
    }
}
