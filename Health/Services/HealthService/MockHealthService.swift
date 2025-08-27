//
//  MockHealthService.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import HealthKit

/// HealthKit 데이터를 처리하는 목 구현체입니다.
///
/// - Important: 임의의 목(mock) 데이터만 반환합니다. 반드시 `RELEASE` 스킴으로 전환 후, 테스트를 진행하세요.
final class MockHealthService: HealthService {

    init() {
//        HKQuantityType(.activeEnergyBurned)                // 활동 에너지
//        HKQuantityType(.basalEnergyBurned)                 // 휴식 에너지
//        HKQuantityType(.distanceWalkingRunning)            // 걷기 + 달리기 거리
//        HKQuantityType(.appleExerciseTime)                 // 운동하기 시간
//        HKQuantityType(.stepCount)                         // 걸음 수
//        HKQuantityType(.walkingStepLength)                 // 보행 보폭
//        HKQuantityType(.walkingAsymmetryPercentage)        // 보행 비대칭성
//        HKQuantityType(.walkingSpeed)                      // 보행 속도
//        HKQuantityType(.walkingDoubleSupportPercentage)    // 이중 지지 시간
//        HKQuantityType(.height)                            // 신장(height)
//        HKQuantityType(.bodyMass)                          // 몸무게
//        HKQuantityType(.bodyMassIndex)                     // BMI 수치
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        return true
    }

    func checkHasAnyReadPermission() async -> Bool {
        return true
    }

    func checkHasReadPermission(for identifier: HKQuantityTypeIdentifier) async -> Bool {
        return true
    }


    // MARK: - Samples

    func fetchSamples(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        limit: Int = HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor]? = nil,
        unit: HKUnit
    ) async throws -> [HKData] {
        let (startDate, endDate) = Date.now.rangeOfDay()
        return [HKData(startDate: startDate, endDate: endDate, value: 10.0)]
    }


    // MARK: - Statistics

    func fetchStatistics(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        unit: HKUnit
    ) async throws -> HKData {
        let (startDate, endDate) = Date.now.rangeOfDay()

        let mockValues: [HKQuantityTypeIdentifier: Double] = [
            .activeEnergyBurned: 148.0,           // 활동 에너지 (kcal)
            .basalEnergyBurned: 1400.0,           // 휴식 에너지 (kcal)
            .distanceWalkingRunning: 80.0,        // 걷기+달리기 거리 (km )
            .appleExerciseTime: 42.0,             // 운동 시간 (분)
            .stepCount: 8_540,                    // 걸음 수
            .flightsClimbed: 13,                  // 오른 층수
            .walkingStepLength: 72,               // 보행 보폭 (cm)
            .walkingAsymmetryPercentage: 0.27,    // 보행 비대칭성 (%)
            .walkingSpeed: 1.32,                  // 보행 속도 (m/s)
            .walkingDoubleSupportPercentage: 0.17 // 이중 지지 시간 (%)
        ]

        let value = mockValues[identifier] ?? -1
        return HKData(startDate: startDate, endDate: endDate, value: value)
    }


    // MARK: - Statistics Collection

    func fetchStatisticsCollection(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents,
        unit: HKUnit
    ) async throws -> [HKData] {
        var hkDatas: [HKData] = []
        if let _ = intervalComponents.day {
            let diff = startDate.dayDiff(to: endDate)
            for index in 0..<diff {
                let date = Date.now.addingDays(-index)!
//                if index == 0 { continue }
//                if index == 6 { continue }
                let (startDate, endDate) = date.rangeOfDay()
                hkDatas.append(HKData(startDate: startDate, endDate: endDate, value: Double.random(in: 1..<1000)))
            }
        } else {
            let diff = startDate.monthDiff(to: endDate)
            for index in 0..<diff {
                let date = Date.now.addingMonths(-index)!
//                if index == 3 { continue }
//                if index == 5 { continue }
                let (startDate, endDate) = date.rangeOfMonth()
                hkDatas.append(HKData(startDate: startDate!, endDate: endDate!, value: Double.random(in: 1..<1000)))
            }
        }
        return hkDatas
    }
}
