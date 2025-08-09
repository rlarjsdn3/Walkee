//
//  InjectIdentifier+Extension.swift
//  DIContainerProject
//
//  Created by 김건우 on 7/26/25.
//

import Foundation

/// 의존성 주입에 사용되는 식별자 키들을 정의하는 `InjectIdentifier` 확장
///
/// 이 확장은 타입 안전성을 보장하면서 의존성 주입 컨테이너에서
/// 서비스들을 식별하는 데 사용되는 정적 속성들을 제공합니다.
extension InjectIdentifier {

    /// 네트워크 서비스를 식별하는 정적 속성
    ///
    /// `NetworkService` 프로토콜을 구현하는 서비스들을 의존성 주입 컨테이너에서
    /// 등록하고 해결할 때 사용되는 타입 안전한 식별자입니다.
    ///
    /// - Returns: `NetworkService` 타입의 `InjectIdentifier` 인스턴스
    /// - Note: 이 식별자는 컴파일 타임에 타입 안전성을 보장합니다.
    static var networkService: InjectIdentifier<NetworkService> {
        InjectIdentifier<NetworkService>(type: NetworkService.self)
    }

    /// 건간 데이터 조회 서비스를 식별하는 정적 속성
    ///
    /// `HealthService` 프로토콜을 구현하는 서비스들을 의존성 주입 컨테이너에서
    /// 등록하고 해결할 때 사용되는 타입 안전한 식별자입니다.
    ///
    /// - Returns: `HealthService` 타입의 `InjectIdentifier` 인스턴스
    /// - Note: 이 식별자는 컴파일 타임에 타입 안전성을 보장합니다.
    static var healthService: InjectIdentifier<HealthService> {
        InjectIdentifier<HealthService>(type: HealthService.self)
    }

    /// 일일 걸음 수 관리 ViewModel을 식별하는 정적 속성
    ///
    /// `DailyStepViewModel` 클래스를 의존성 주입 컨테이너에서
    /// 등록하고 해결할 때 사용되는 타입 안전한 식별자입니다.
    ///
    /// - Returns: `DailyStepViewModel` 타입의 `InjectIdentifier` 인스턴스
    /// - Note: Core Data의 `viewContext`와 함께 초기화됩니다.
    static var dailyStepViewModel: InjectIdentifier<DailyStepViewModel> {
        InjectIdentifier<DailyStepViewModel>(type: DailyStepViewModel.self)
    }

    /// 목표 걸음 수 설정 ViewModel을 식별하는 정적 속성
    ///
    /// `GoalStepCountViewModel` 클래스를 의존성 주입 컨테이너에서
    /// 등록하고 해결할 때 사용되는 타입 안전한 식별자입니다.
    ///
    /// - Returns: `GoalStepCountViewModel` 타입의 `InjectIdentifier` 인스턴스
    /// - Note: Core Data의 `viewContext`와 함께 초기화됩니다.
    static var goalStepCountViewModel: InjectIdentifier<GoalStepCountViewModel> {
        InjectIdentifier<GoalStepCountViewModel>(type: GoalStepCountViewModel.self)
    }

    /// 걸음 수 동기화 ViewModel을 식별하는 정적 속성
    ///
    /// `StepSyncViewModel` 클래스를 의존성 주입 컨테이너에서
    /// 등록하고 해결할 때 사용되는 타입 안전한 식별자입니다.
    ///
    /// - Returns: `StepSyncViewModel` 타입의 `InjectIdentifier` 인스턴스
    /// - Important: 이 ViewModel은 `@Injected` 프로퍼티를 통해 다른 서비스들에 의존하므로,
    ///   해당 서비스들이 먼저 등록되어 있어야 합니다.
    static var stepSyncViewModel: InjectIdentifier<StepSyncViewModel> {
        InjectIdentifier<StepSyncViewModel>(type: StepSyncViewModel.self)
    }
}
