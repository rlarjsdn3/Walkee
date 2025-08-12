//
//  HealthService.swift
//  HealthKitService
//
//  Created by 김건우 on 8/4/25.
//

import Foundation
import HealthKit

/// HealthKit 데이터를 처리하는 기본 구현체입니다.
///
/// 이 클래스는 `HealthService` 프로토콜을 채택하며,
/// HealthKit 권한 요청, 샘플 데이터 조회, 통계 계산 등의 기능을 제공합니다.
/// 앱 내에서 건강 데이터를 읽거나 가공하는 데에 사용됩니다.
///
/// - Note: HealthKit 접근을 위해 `HKHealthStore`를 내부적으로 사용합니다.
///         실제 기기에서만 작동하며, 사용 전 권한 요청이 선행되어야 합니다.
final class DefaultHealthService: HealthService {

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
    
    /// HealthKit 데이터에 접근하기 위한 권한을 비동기적으로 요청합니다.
    //
    /// - Throws: 기기가 HealthKit을 지원하지 않거나, 권한 요청 중 오류가 발생하면 `HKError`를 throw합니다.
    ///
    /// 사용자의 동의를 받아야만 HealthKit 데이터를 읽거나 쓸 수 있으므로,
    ///         이 메서드는 앱 실행 초기에 반드시 호출되어야 합니다.
    ///
    /// - Important: iOS 시뮬레이터는 HealthKit을 지원하지 않으며, 실제 기기에서만 정상 동작합니다.
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HKError(.errorHealthDataUnavailable)
        }
        
        try await healthStore.requestAuthorization(
            toShare: [],
            read: typesForAuthorization
        )
        
        return await checkHasAnyReadPermission()
    }

    /// HealthKit에서 읽기 권한이 부여된 데이터 타입이 하나라도 있는지 비동기적으로 검사합니다.
    ///
    /// 이 메서드는 `typesForAuthorization`에 포함된 모든 HealthKit 데이터 타입의
    /// 권한 상태를 병렬로 확인합니다. 하나라도 읽기 권한(`.sharingAuthorized`)이 있으면
    /// `true`, 전혀 없으면 `false`를 반환합니다.
    ///
    /// - Important: 온보딩 또는 설정 화면에서 스위치 상태(on/off)를 갱신할 때 활용하세요.
    /// - Returns: 읽기 권한이 하나라도 허가되었으면 `true`, 아니면 `false`를 반환합니다.
    func checkHasAnyReadPermission() async -> Bool {
        
        await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
            for type in typesForAuthorization {
                group.addTask {
                    return await self.authorizationStatus(
                        for: HKQuantityTypeIdentifier(rawValue: type.identifier)
                    )
                }
            }
            
            for await bool in group {
                if bool { return true }
            }
            
            return false
        }
    }


    
    // MARK: - Samples
    
    /// 지정한 양적 데이터(identifier)를 기준으로 HealthKit에서 샘플 데이터를 비동기적으로 가져오고,
    /// 각 샘플의 시작 시각, 종료 시각, 수치를 지정된 단위로 변환하여 반환합니다.
    ///
    /// - Parameters:
    ///   - identifier: 가져올 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.walkingSpeed`.
    ///   - startDate: 데이터를 조회할 시작 날짜입니다.
    ///   - endDate: 데이터를 조회할 종료 날짜입니다.
    ///   - limit: 가져올 데이터의 최대 개수입니다. 기본값은 `HKObjectQueryNoLimit`입니다.
    ///   - sortDescriptors: 정렬 방식입니다. 예: 종료일 내림차순 등. 기본값은 `nil`입니다.
    ///   - unit: 수치를 변환할 단위입니다. 예: `.count()`, `.meter()` 등.
    ///
    /// - Returns: 각 샘플의 `(startDate, endDate, value)`를 포함하는 `[HKResult]` 배열입니다.
    /// - Throws: HealthKit 권한이 없거나, 데이터 조회 중 문제가 발생하면 오류를 throw합니다.
    ///
    /// 사전에 `HKHealthStore.requestAuthorization`을 통해 권한이 승인되어 있어야 하며,
    /// 권한이 없을 경우 런타임 중 오류가 발생할 수 있습니다.
    func fetchSamples(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        limit: Int = HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor]? = nil,
        unit: HKUnit
    ) async throws -> [HKData] {
        let samples: [HKQuantitySample] = try await fetchSamples(
            for: identifier,
            from: startDate,
            to: endDate,
            limit: limit,
            sortDescriptors: sortDescriptors
        )
       
        return samples.map { sample in
            HKData(
                startDate: sample.startDate,
                endDate: sample.endDate,
                value: sample.quantity.doubleValue(for: unit)
            )
        }
    }
    
    /// 지정한 HealthKit 양적 데이터(identifier)에 해당하는 샘플 데이터를 비동기적으로 가져옵니다.
    ///
    /// - Parameters:
    ///   - identifier: 가져올 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.walkingSpeed`.
    ///   - startDate: 데이터를 조회할 시작 날짜입니다.
    ///   - endDate: 데이터를 조회할 종료 날짜입니다.
    ///   - limit: 가져올 데이터 개수의 최대값입니다. 기본값은 `HKObjectQueryNoLimit`입니다.
    ///   - sortDescriptors: 정렬 방식입니다. 예: 종료일 기준 내림차순 등.
    ///
    /// - Returns: 조건에 해당하는 `[HKQuantitySample]` 배열을 반환합니다.
    /// - Throws: HealthKit 권한이 없거나, 데이터 조회 중 문제가 발생하면 오류를 throw합니다.
    ///
    /// 사전에 `HKHealthStore.requestAuthorization`을 통해 권한이 승인되어 있어야 하며,
    /// 권한이 없을 경우 런타임 중 오류가 발생할 수 있습니다.
    func fetchSamples(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        limit: Int = HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) async throws -> [HKQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            fetchSamples(
                for: identifier,
                from: startDate,
                to: endDate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { result in
                switch result {
                case let .success(samples):
                    let samplesAsQuantitySamples = samples
                        .compactMap { $0 as? HKQuantitySample }
                    print(samplesAsQuantitySamples)
                    continuation.resume(returning: samplesAsQuantitySamples)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 지정한 HealthKit 양적 데이터(identifier)에 해당하는 샘플 데이터를 가져옵니다.
    ///
    /// - Parameters:
    ///   - identifier: 가져올 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.walkingSpeed`.
    ///   - startDate: 샘플 데이터를 가져올 시작 시각입니다.
    ///   - endDate: 샘플 데이터를 가져올 종료 시각입니다.
    ///   - limit: 가져올 샘플 수의 최대값입니다. 기본값은 `HKObjectQueryNoLimit`입니다.
    ///   - sortDescriptors: 샘플 정렬 방식입니다. 예: 종료일 기준 내림차순 등.
    ///   - completion: 성공 시 `HKQuantitySample` 배열을 반환하며, 실패 시 `Error`를 반환합니다.
    ///
    /// 사전에 `HKHealthStore.requestAuthorization`을 통해 권한이 승인되어 있어야 하며,
    /// 권한이 없을 경우 런타임 중 오류가 발생할 수 있습니다.
    func fetchSamples(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        limit: Int = HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor]? = nil,
        completion: @escaping HKSampleCompletionHandler
    ) {
        let type = HKQuantityType(identifier)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        ) { query, samples, error in
            if let error = error {
                completion(.failure(error))
                return
            } else {
                guard let samples = samples else {
                    completion(.failure(HKError(.errorNoData)))
                    return
                }
                let samplesAsQuantitySamples = samples
                    .compactMap { $0 as? HKQuantitySample }
                Task { @MainActor in
                    completion(.success(samplesAsQuantitySamples))
                }
                return
            }
        }
        healthStore.execute(query)
    }
    
    
    // MARK: - Statistics
    
    /// 지정한 양적 데이터(identifier)에 대해 통계 값을 비동기적으로 조회하고, 결과 값을 단위에 맞게 변환하여 반환합니다.
    ///
    /// - Parameters:
    ///   - identifier: 조회할 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.walkingSpeed`.
    ///   - startDate: 통계를 계산할 시작 날짜입니다.
    ///   - endDate: 통계를 계산할 종료 날짜입니다.
    ///   - options: 통계를 계산할 방식입니다. 예: `.cumulativeSum`, `.mostRecent`, `.discreteAverage` 등.
    ///   - unit: 통계 결과 수치를 변환할 단위입니다. 예: `.count()`, `.meter()` 등.
    ///
    /// - Returns: `(startDate, endDate, value)`로 구성된 `HKResult` 튜플을 반환합니다.
    /// - Throws: 권한이 없거나, 데이터가 없거나, 통계 값이 유효하지 않을 경우 오류를 throw합니다.
    ///
    /// 사전에 `HKHealthStore.requestAuthorization`을 통해 권한이 승인되어 있어야 하며,
    /// 권한이 없을 경우 런타임 중 오류가 발생할 수 있습니다.
    ///
    /// - Important: `identifier`와 `options`의 조합에 따라 통계 계산이 불가능한 경우가 있을 수 있으므로, 매우 주의해서 전달해야 합니다.
    /// 예를 들어, 보행 비대칭성(`walkingAsymmetryPercentage`)은 누적이 의미 없는 데이터이므로 `.cumulativeSum` 옵션과 함께 사용할 수 없습니다.
    /// 이처럼 부적절한 조합으로 함수를 호출할 경우, 런타임 중 오류가 발생할 수 있습니다.
    /// HealthKit 문서를 참고하여 각 데이터 타입에 적절한 `HKStatisticsOptions`를 선택하세요.
    func fetchStatistics(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        unit: HKUnit
    ) async throws -> HKData {
        let stat: HKStatistics = try await fetchStatistics(
            for: identifier,
            from: startDate,
            to: endDate,
            options: options
        )
        
        guard let value = options.quantity(for: stat, unit: unit)
        else { throw HKError(.errorHealthDataUnavailable) }
        return HKData(startDate: stat.startDate, endDate: stat.endDate, value: value)
    }

    /// 지정한 양적 데이터(identifier)에 대해 통계 정보를 비동기적으로 가져옵니다.
    ///
    /// - Parameters:
    ///   - identifier: 조회할 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.activeEnergyBurned`.
    ///   - startDate: 통계를 계산할 시작 날짜입니다.
    ///   - endDate: 통계를 계산할 종료 날짜입니다.
    ///   - options: 통계를 계산할 방식입니다. 예: `.cumulativeSum`, `.discreteAverage`, `.mostRecent` 등.
    ///
    /// - Returns: 지정한 옵션에 따라 계산된 `HKStatistics` 객체를 반환합니다.
    /// - Throws: HealthKit 권한이 없거나 데이터가 존재하지 않을 경우 오류를 throw합니다.
    ///
    /// 사전에 `HKHealthStore.requestAuthorization`을 통해 권한이 승인되어 있어야 하며,
    /// 권한이 없을 경우 런타임 중 오류가 발생할 수 있습니다.
    ///
    /// - Important: `identifier`와 `options`의 조합에 따라 통계 계산이 불가능한 경우가 있을 수 있으므로, 매우 주의해서 전달해야 합니다.
    /// 예를 들어, 보행 비대칭성(`walkingAsymmetryPercentage`)은 누적이 의미 없는 데이터이므로 `.cumulativeSum` 옵션과 함께 사용할 수 없습니다.
    /// 이처럼 부적절한 조합으로 함수를 호출할 경우, 런타임 중 오류가 발생할 수 있습니다.
    /// HealthKit 문서를 참고하여 각 데이터 타입에 적절한 `HKStatisticsOptions`를 선택하세요.
    func fetchStatistics(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics {
        try await withCheckedThrowingContinuation { continuation in
            fetchStatistics(
                for: identifier,
                from: startDate,
                to: endDate,
                options: options
            ) { result in
                switch result {
                case let .success(stat):
                    continuation.resume(returning: stat)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 지정한 양적 데이터(identifier)에 대해 통계 정보를 조회합니다.
    ///
    /// - Parameters:
    ///   - identifier: 조회할 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.activeEnergyBurned`.
    ///   - startDate: 통계를 계산할 시작 날짜입니다.
    ///   - endDate: 통계를 계산할 종료 날짜입니다.
    ///   - options: 통계를 계산할 옵션입니다. 예: `.cumulativeSum`, `.discreteAverage`, `.mostRecent` 등.
    ///   - completion: 성공 시 `HKStatistics`를 반환하고, 실패 시 `Error`를 반환하는 클로저입니다.
    ///
    /// 사전에 `HKHealthStore.requestAuthorization`을 통해 권한이 승인되어 있어야 하며,
    /// 권한이 없을 경우 런타임 중 오류가 발생할 수 있습니다.
    ///
    /// - Important: `identifier`와 `options`의 조합에 따라 통계 계산이 불가능한 경우가 있을 수 있으므로, 매우 주의해서 전달해야 합니다.
    /// 예를 들어, 보행 비대칭성(`walkingAsymmetryPercentage`)은 누적이 의미 없는 데이터이므로 `.cumulativeSum` 옵션과 함께 사용할 수 없습니다.
    /// 이처럼 부적절한 조합으로 함수를 호출할 경우, 런타임 중 오류가 발생할 수 있습니다.
    /// HealthKit 문서를 참고하여 각 데이터 타입에 적절한 `HKStatisticsOptions`를 선택하세요.
    func fetchStatistics(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        completion: @escaping HKStatisticsCompletionHandler
    ) {
        let type = HKQuantityType(identifier)

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: options
        ) { query, statistics, error in
            if let error = error {
                completion(.failure(error))
                return
            } else {
                guard let stat = statistics else {
                    completion(.failure(HKError(.errorNoData)))
                    return
                }
                Task { @MainActor in
                    completion(.success(stat))
                }
                return
            }
        }
        healthStore.execute(query)
    }
    
    
    // MARK: - Statistics Collection
    
    /// 지정한 양적 데이터(identifier)에 대해 일정 구간(interval) 단위로 통계 정보를 비동기적으로 가져오고,
    /// 각 통계 구간의 시작/종료 시간 및 수치를 단위에 맞게 변환하여 반환합니다.
    ///
    /// - Parameters:
    ///   - identifier: 조회할 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.walkingSpeed`.
    ///   - startDate: 통계를 계산할 시작 날짜입니다.
    ///   - endDate: 통계를 계산할 종료 날짜입니다.
    ///   - options: 통계를 계산할 방식입니다. 예: `.cumulativeSum`, `.discreteAverage` 등.
    ///   - intervalComponents: 통계를 구간별로 나누기 위한 `DateComponents`입니다. 예: 하루 단위 → `DateComponents(day: 1)`
    ///   - unit: 수치를 변환할 단위입니다. 예: `.count()`, `.meter()` 등.
    ///
    /// - Returns: 각 구간별 `(startDate, endDate, value)`로 구성된 `HKResult` 배열을 반환합니다.
    /// - Throws: HealthKit 권한이 없거나, 데이터 조회 또는 값 변환 중 문제가 발생할 경우 오류를 throw합니다.
    ///
    /// - Important: `identifier`와 `options`의 조합에 따라 통계 계산이 불가능한 경우가 있으므로, 매우 주의해서 전달해야 합니다.
    ///              예를 들어, 보행 비대칭성(`walkingAsymmetryPercentage`)은 누적이 의미 없는 데이터이므로 `.cumulativeSum` 옵션과 함께 사용할 수 없습니다.
    ///              이처럼 부적절한 조합으로 함수를 호출할 경우, 런타임 중 오류가 발생할 수 있습니다.
    ///              반드시 Apple의 HealthKit 공식 문서를 참고하여 적절한 옵션을 선택하세요.
    func fetchStatisticsCollection(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents,
        unit: HKUnit
    ) async throws -> [HKData] {
        let stats: [HKStatistics] = try await fetchStatisticsCollection(
            for: identifier,
            from: startDate,
            to: endDate,
            options: options,
            interval: intervalComponents
        )
        
        return stats.compactMap { stat in
            guard let value = options.quantity(for: stat, unit: unit) else {
                return nil
            }
            return HKData(startDate: stat.startDate, endDate: stat.endDate, value: value)
        }
    }
    
    /// 지정한 양적 데이터(identifier)에 대해 일정 구간(interval) 단위로 통계 정보를 비동기적으로 가져옵니다.
    ///
    /// - Parameters:
    ///   - identifier: 조회할 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.walkingSpeed`.
    ///   - startDate: 통계를 계산할 시작 날짜입니다.
    ///   - endDate: 통계를 계산할 종료 날짜입니다.
    ///   - options: 통계를 계산할 방식입니다. 예: `.cumulativeSum`, `.discreteAverage` 등.
    ///   - intervalComponents: 통계를 구간별로 나누기 위한 `DateComponents`입니다. 예: 하루 단위 → `DateComponents(day: 1)`
    ///
    /// - Returns: 각 구간에 해당하는 `HKStatistics` 객체의 배열을 반환합니다.
    /// - Throws: HealthKit 권한이 없거나, 데이터 조회 중 문제가 발생할 경우 오류를 throw합니다.
    ///
    /// - Important: `identifier`와 `options`의 조합에 따라 통계 계산이 불가능한 경우가 있으므로, 매우 주의해서 전달해야 합니다.
    ///              예를 들어, 보행 비대칭성(`walkingAsymmetryPercentage`)은 누적이 의미 없는 데이터이므로 `.cumulativeSum` 옵션과 함께 사용할 수 없습니다.
    ///              이처럼 부적절한 조합으로 함수를 호출하면 런타임 중 오류가 발생할 수 있습니다.
    ///              반드시 Apple의 HealthKit 공식 문서를 참고하여 적절한 옵션을 선택하세요.
    func fetchStatisticsCollection(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents
    ) async throws -> [HKStatistics] {
        try await withCheckedThrowingContinuation { continuation in
            fetchStatisticsCollection(
                for: identifier,
                anchor: startDate,
                options: options,
                interval: intervalComponents
            ) { result in
                switch result {
                case let .success(statCollection):
                    var stats: [HKStatistics] = []
                    statCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                        stats.append(statistics)
                    }
                    continuation.resume(returning: stats)
                    
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 지정한 양적 데이터(identifier)에 대해 통계를 일정 구간(interval) 단위로 나누어 계산합니다.
    ///
    /// - Parameters:
    ///   - identifier: 조회할 `HKQuantityTypeIdentifier`입니다. 예: `.stepCount`, `.walkingSpeed`.
    ///   - startDate: 통계를 계산할 시작 날짜입니다.
    ///   - endDate: 통계를 계산할 종료 날짜입니다.
    ///   - options: 통계를 계산할 방식입니다. 예: `.cumulativeSum`, `.discreteAverage` 등.
    ///   - intervalComponents: 통계를 구간별로 나누기 위한 `DateComponents`입니다. 예: 하루 단위 → `DateComponents(day: 1)`
    ///   - initialResultsHandler: 성공 시 `HKStatisticsCollection`을 반환하고, 실패 시 `Error`를 반환하는 클로저입니다.
    ///
    /// - Important: `identifier`와 `options`의 조합에 따라 통계 계산이 불가능한 경우가 있을 수 있으므로, 매우 주의해서 전달해야 합니다.
    ///              예를 들어, 보행 비대칭성(`walkingAsymmetryPercentage`)은 누적이 의미 없는 데이터이므로 `.cumulativeSum` 옵션과 함께 사용할 수 없습니다.
    ///              이처럼 부적절한 조합으로 함수를 호출할 경우, 런타임 중 오류가 발생할 수 있습니다.
    ///              HealthKit 문서를 참고하여 각 데이터 타입에 적절한 `HKStatisticsOptions`를 선택하세요.
    func fetchStatisticsCollection(
        for identifier: HKQuantityTypeIdentifier,
        anchor anchorDate: Date,
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents,
        initialResultsHandler: @escaping HKStatisticsCollectionCompletionHandler
    ) {
        let type = HKQuantityType(identifier)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: nil,
            options: options,
            anchorDate: anchorDate,
            intervalComponents: intervalComponents
        )
        query.initialResultsHandler = { query, statisticCollection, error in
            if let error = error {
                initialResultsHandler(.failure(error))
                return
            } else {
                guard let statCollection = statisticCollection else {
                    initialResultsHandler(.failure(HKError(.errorHealthDataUnavailable)))
                    return
                }
                Task { @MainActor in
                    initialResultsHandler(.success(statCollection))
                }
                return
            }
        }
        
        healthStore.execute(query)
    }
}



// MARK: - Helper

fileprivate extension DefaultHealthService  {
    
    func authorizationStatus(for identifier: HKQuantityTypeIdentifier) async -> Bool {
        guard let fromDate: Date = .now.addingDays(-365)
        else { return false }
        
        // 1년 전부터 오늘까지의 특정 데이터를 하나라도 가져올 수 있다면 읽기 권한이 허가된 걸로 간주합니다.
        return await withCheckedContinuation { continuation in
            fetchSamples(
                for: identifier,
                from: fromDate,
                to: .now,
                limit: 1,
                sortDescriptors: nil
            ) { result in
                switch result {
                case .success(let sample):
                    if !sample.isEmpty { continuation.resume(returning: true) }
                    else { continuation.resume(returning: false) }
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
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
