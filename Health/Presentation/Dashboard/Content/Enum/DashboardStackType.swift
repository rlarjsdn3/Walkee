//
//  DashboardStackType.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import HealthKit

enum DashboardStackType: CaseIterable {

    ///
    case distanceWalkingRunning
    ///
    case appleExerciseTime
    ///
    case activeEnergyBurned
    ///
    case basalEnergyBurned
}

extension DashboardStackType {

    ///
    var title: String? {
        switch self {
        case .distanceWalkingRunning:           return "걸은 거리"
        case .appleExerciseTime:                return "운동 시간"
        case .activeEnergyBurned:               return "활동 에너지"
        case .basalEnergyBurned:                return "휴식 에너지"
        }
    }

    ///
    var systemName: String {
        switch self {
        case .distanceWalkingRunning:           return "location.fill"
        case .appleExerciseTime:                return "timer"
        case .activeEnergyBurned:               return "flame.fill"
        case .basalEnergyBurned:                return "flame"
        }
    }

    ///
    var unit: HKUnit {
        switch self {
        case .distanceWalkingRunning:         return HKUnit.meterUnit(with: .kilo)
        case .appleExerciseTime:              return HKUnit.minute()
        case .activeEnergyBurned:             return HKUnit.kilocalorie()
        case .basalEnergyBurned:              return HKUnit.kilocalorie()
        }
    }

    ///
    var unitString: String {
        switch self {
        case .distanceWalkingRunning:         return "km"
        case .appleExerciseTime:              return "분"
        case .activeEnergyBurned:             return "kcal"
        case .basalEnergyBurned:              return "kcal"
        }
    }

    ///
    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .distanceWalkingRunning:           return .distanceWalkingRunning
        case .appleExerciseTime:                return .appleExerciseTime
        case .activeEnergyBurned:               return .activeEnergyBurned
        case .basalEnergyBurned:                return .basalEnergyBurned
        }
    }
}
