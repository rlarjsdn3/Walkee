//
//  HealthService.swift
//  HealthKitService
//
//  Created by 김건우 on 8/4/25.
//

// 추가로 해야할 일: 주석 작성, 목 데이터 작성, DEBUG 스킴에서 목 데이터 반환하도록 코드 수정

import Foundation
import HealthKit

/// HealthKit 관련 기능을 정의한 프로토콜입니다.
///
/// HealthKit 데이터 접근 권한 요청, 샘플 데이터 및 통계 데이터를 가져오는 메서드를 정의합니다.
/// 모든 메서드는 메인 액터에서 실행되어야 하며, HealthKit 데이터를 안전하게 다루기 위해 비동기 처리 및 에러 처리를 포함합니다.
@MainActor
protocol HealthService {

    /// HealthKit 통계 결과를 표현하는 튜플 타입입니다.
    /// - Parameters:
    ///   - startDate: 통계 시작 날짜
    ///   - endDate: 통계 종료 날짜
    ///   - value: 해당 기간 동안의 측정값
    typealias HKResult = (startDate: Date, endDate: Date, value: Double)

    /// HealthKit 샘플 데이터를 반환하는 클로저 타입입니다.
    /// - Parameter Result: 성공 시 `HKSample` 배열을 반환하며, 실패 시 에러를 반환합니다.
    typealias HKSampleCompletionHandler = @Sendable (Result<[HKSample], (any Error)>) -> Void

    /// HealthKit 통계 데이터를 반환하는 클로저 타입입니다.
    /// - Parameter Result: 성공 시 `HKStatistics` 객체를 반환하며, 실패 시 에러를 반환합니다.
    typealias HKStatisticsCompletionHandler = @Sendable (Result<HKStatistics, (any Error)>) -> Void

    /// HealthKit 통계 컬렉션 데이터를 반환하는 클로저 타입입니다.
    /// - Parameter Result: 성공 시 `HKStatisticsCollection` 객체를 반환하며, 실패 시 에러를 반환합니다.
    typealias HKStatisticsCollectionCompletionHandler = @Sendable (Result<HKStatisticsCollection, (any Error)>) -> Void

    /// HealthKit 데이터 접근 권한을 요청합니다.
    ///
    /// 사용자의 동의를 받아 HealthKit 데이터 읽기 및 쓰기 권한을 요청합니다.
    /// HealthKit 사용 가능 여부를 확인한 후, 권한 요청을 수행합니다.
    /// - Throws: `HKError.errorHealthDataUnavailable` 또는 권한 요청 실패 시 에러를 던집니다.
    func requestAuthorization() async throws


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
        limit: Int,
        sortDescriptors: [NSSortDescriptor]?,
        unit: HKUnit
    ) async throws -> [HKResult]
    
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
        limit: Int,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [HKQuantitySample]



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
    ) async throws -> HKResult
    
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
    ) async throws -> HKStatistics



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
    ) async throws -> [HKResult]
    
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
    ) async throws -> [HKStatistics]
}
