//
//  DefaultPromptGenService.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import HealthKit

final class DefaultPromptGenService: PromptGenService {
    
    private var renderer: (any PromptTemplateRenderer)
    @Injected private var userService: (any CoreDataUserService)
    @Injected private var healthService: (any HealthService)
    
    init(renderer: any PromptTemplateRenderer = DefaultPromptTemplateRenderer()) {
        self.renderer = renderer
    }
    
    func makePrompt(message extraInstructions: String, context: PromptContext? = nil, option: PromptOption) async throws -> String {
        // 사용자 나이 및 생년월일 정보 가져오기
        let userInfo = try userService.fetchUserInfo()
        print(userInfo)
        
        // 사용자 건강 정보 가져오기
        async let stepCount = try fetchHKData(.stepCount)
        async let distanceWalkingRunning = try fetchHKData(.distanceWalkingRunning)
        async let activeEnergyBurned = try fetchHKData(.activeEnergyBurned)
        async let basalEnergyBurned = try fetchHKData(.basalEnergyBurned)
        async let walkingSpeed = try fetchHKData(.walkingSpeed, options: .mostRecent, unit: .meter().unitDivided(by: .second()))
        async let stepLength = try fetchHKData(.walkingStepLength, options: .mostRecent, unit: .meterUnit(with: .centi))
        async let doubleSupportPercentage = try fetchHKData(.walkingDoubleSupportPercentage, options: .mostRecent, unit: .percent())
        async let asymmetryPercentage = try fetchHKData(.walkingAsymmetryPercentage, options: .mostRecent, unit: .percent())
        async let last7DaysStepCounts = try healthService.fetchStatisticsCollection(
            for: .stepCount,
            from: Date.now.startOfDay().addingDays(-7) ?? .now,
            to: Date.now.endOfDay(),
            options: .cumulativeSum,
            interval: .init(day: 1),
            unit: .count()
        )
        async let last12MonthsStepCounts = try healthService.fetchStatisticsCollection(
            for: .stepCount,
            from: Date.now.startOfMonth()?.addingMonths(-12) ?? .now,
            to: Date.now.endOfMonth() ?? .now,
            options: .cumulativeSum,
            interval: .init(month: 1),
            unit: .count()
        )
        // TODO: - HealthService에서 가져오는 QuantityType과 HKUnit을 쉽게 일치시킬 방안 강구하기
        
        let userDesc = UserDescriptor(
            age: Int(userInfo.age),
            gender: userInfo.gender!
        )
        let healthDesc = HealthDescriptor(
            weight: userInfo.weight,
            height: userInfo.height,
            diseases: userInfo.diseases,
            stepCount: try await stepCount,
            distanceWalkingRunning: try await distanceWalkingRunning,
            activeEnergyBurned: try await activeEnergyBurned,
            basalEnergyBurned: try await basalEnergyBurned,
            walkingSpeed: try await walkingSpeed,
            stepLength: try await stepLength,
            stepSpeed: try await walkingSpeed,
            walkingAsymmetryPercentage: try await asymmetryPercentage,
            doubleSupportPercentage: try await doubleSupportPercentage,
            last7DaysStepCounts: try await last7DaysStepCounts,
            last12MonthsStepCounts: try await last12MonthsStepCounts
        )
        let context = PromptContext(
            user: userDesc,
            health: healthDesc
        )
        
        var prompt = renderer.render(with: context, option: option)
        prompt.append(extraInstructions)
        return prompt
    }
    
    private func fetchHKData(
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
            options: .cumulativeSum,
            unit: .count()
        ).value
    }
    
}
