//
//  DashboardStackKind.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import HealthKit

enum DashboardStackKind: CaseIterable {

    /// 걷기 및 달리기 거리 스택
    case distanceWalkingRunning
    /// 운동 시간 스택
    case appleExerciseTime
    /// 활동 에너지 소모 스택
    case activeEnergyBurned
    /// 기초 대사량 소모 스택
    case basalEnergyBurned
    /// 오른 층수 스택
    case flightsClimbed
}

extension DashboardStackKind {

    var title: String? {
        switch self {
        case .distanceWalkingRunning:           return "걸은 거리"
        case .appleExerciseTime:                return "운동 시간"
        case .activeEnergyBurned:               return "활동 에너지"
        case .basalEnergyBurned:                return "휴식 에너지"
        case .flightsClimbed:                   return "오른 층수"
        }
    }

    var systemName: String {
        switch self {
        case .distanceWalkingRunning:           return "location.fill"
        case .appleExerciseTime:                return "timer"
        case .activeEnergyBurned:               return "flame.fill"
        case .basalEnergyBurned:                return "sleep.circle.fill"
        case .flightsClimbed:                   return "figure.stairs"
        }
    }

    var unit: HKUnit {
        switch self {
        case .distanceWalkingRunning:         return HKUnit.meterUnit(with: .kilo)
        case .appleExerciseTime:              return HKUnit.minute()
        case .activeEnergyBurned:             return HKUnit.kilocalorie()
        case .basalEnergyBurned:              return HKUnit.kilocalorie()
        case .flightsClimbed:                 return HKUnit.count()
        }
    }

    var unitString: String {
        switch self {
        case .distanceWalkingRunning:         return "km"
        case .appleExerciseTime:              return "분"
        case .activeEnergyBurned:             return "kcal"
        case .basalEnergyBurned:              return "kcal"
        case .flightsClimbed:                 return "층"
        }
    }

    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .distanceWalkingRunning:           return .distanceWalkingRunning
        case .appleExerciseTime:                return .appleExerciseTime
        case .activeEnergyBurned:               return .activeEnergyBurned
        case .basalEnergyBurned:                return .basalEnergyBurned
        case .flightsClimbed:                   return .flightsClimbed
        }
    }
}

extension DashboardStackKind: Hashable {
}
