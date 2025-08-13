//
//  MockHealthService.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import Foundation
import HealthKit

/// HealthKit 데이터를 처리하는 목 구현체입니다.
///
/// - Important: 임의의 목(mock) 데이터만 반환합니다. 반드시 `RELEASE` 스킴으로 전환 후, 테스트를 진행하세요.
final class MockHealthService: HealthService {

    private let healthStore = HKHealthStore()

    private(set) var typesForAuthorization: Set<HKQuantityType>
    init() {
        typesForAuthorization = [
            HKQuantityType(.activeEnergyBurned),                // 활동 에너지
            HKQuantityType(.basalEnergyBurned),                 // 휴식 에너지
            HKQuantityType(.distanceWalkingRunning),            // 걷기 + 달리기 거리
            HKQuantityType(.appleExerciseTime),                 // 운동하기 시간
            HKQuantityType(.stepCount),                         // 걸음 수
            HKQuantityType(.walkingStepLength),                 // 보행 보폭
            HKQuantityType(.walkingAsymmetryPercentage),        // 보행 비대칭성
            HKQuantityType(.walkingSpeed),                      // 보행 속도
            HKQuantityType(.walkingDoubleSupportPercentage),    // 이중 지지 시간
            HKQuantityType(.height),                            // 신장(height)
            HKQuantityType(.bodyMass),                          // 몸무게
            HKQuantityType(.bodyMassIndex),                     // BMI 수치
        ]
    }

    // MARK: - Authorization

    ///
    /// - Important: `DEBUG` 모드에서는 아무런 동작을 수행하지 않습니다.
    /// 반드시 `RELEASE` 스킴으로 전환 후, 호출하세요.
    func requestAuthorization() async throws -> Bool {
        return true
    }

    ///
    /// - Important: `DEBUG` 모드에서는 `true` 값만 반환합니다.
    /// 반드시 `RELEASE` 스킴으로 전환 후, 호출하세요.
    func checkHasAnyReadPermission() async -> Bool {
        return true
    }

    ///
    /// - Important: `DEBUG` 모드에서는 `true` 값만 반환합니다.
    /// 반드시 `RELEASE` 스킴으로 전환 후, 호출하세요.
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
        let samples: [HKData] = (0..<10).map { index in
            let date = Date.now.addingTimeInterval(TimeInterval(-index * 86_400))
            let (startDay, endDay) = date.rangeOfDay()
            return HKData(startDate: startDay, endDate: endDay, value: Double.random(in: 0..<10))
        }

        return Array(samples.prefix(through: limit))
    }

    func fetchSamples(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        limit: Int = HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) async throws -> [HKQuantitySample] {
        fatalError("Does not implement in MockHealthService")
    }



    // MARK: - Statistics

    func fetchStatistics(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        unit: HKUnit
    ) async throws -> HKData {
        let date = Date.now
        let (startDay, endDay) = date.rangeOfDay()
        return HKData(startDate: startDay, endDate: endDay, value: 1.4)
    }

    func fetchStatistics(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics {
        fatalError("Does not implement in MockHealthService")
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
        let samples: [HKData] = (0..<7).map { index in
            let date = Date.now.addingTimeInterval(TimeInterval(-index * 86_400))
            let (startDay, endDay) = date.rangeOfDay()
            return HKData(startDate: startDay, endDate: endDay, value: Double.random(in: 1..<1000))
        }

        return samples
    }

    func fetchStatisticsCollection(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents
    ) async throws -> [HKStatistics] {
        fatalError("Does not implement in MockHealthService")
    }
}




fileprivate extension HKStatisticsOptions{

    func quantity(for statistics: HKStatistics, unit: HKUnit) -> Double? {
        var quantity: HKQuantity?
        switch self {
        case _ where self.contains(.cumulativeSum):
            quantity = statistics.sumQuantity()
        case _ where self.contains(.mostRecent):
            quantity = statistics.mostRecentQuantity()
        case _ where self.contains(.discreteAverage):
            quantity = statistics.averageQuantity()
        case _ where self.contains(.discreteMin):
            quantity = statistics.minimumQuantity()
        case _ where self.contains(.discreteMax):
            quantity = statistics.maximumQuantity()
        default:
            return nil
        }

        guard let value = quantity?.doubleValue(for: unit)
        else { return nil }
        return value
    }
}
