//
//  DashboardCardStack.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import HealthKit
import UIKit

///
enum DashboardCardStack {

    ///
    case distanceWalkingRunning
    ///
    case appleExerciseTime
    ///
    case activeEnergyBurned
    ///
    case basalEnergyBurned
    ///
    case walkingStepLength
    ///
    case walkingAsymmetryPercentage
    ///
    case walkingSpeed
    ///
    case walkingDoubleSupportPercentage
}

extension DashboardCardStack {

    ///
    var title: String? {
        switch self {
        case .distanceWalkingRunning:           return "걷기 + 달리기 거리"
        case .appleExerciseTime:                return "운동하기 시간"
        case .activeEnergyBurned:               return "활동 에너지"
        case .basalEnergyBurned:                return "휴식 에너지"
        case .walkingStepLength:                return "보행 보폭"
        case .walkingAsymmetryPercentage:       return "보행 비대칭성"
        case .walkingSpeed:                     return "보행 속도"
        case .walkingDoubleSupportPercentage:   return "이중 지지 시간"
        }
    }

    ///
    var systemName: String {
        switch self {
        case .distanceWalkingRunning:           return "location.fill"
        case .appleExerciseTime:                return "timer"
        case .activeEnergyBurned:               return "flame.fill"
        case .basalEnergyBurned:                return "flame"
        case .walkingStepLength:                return "ruler.fill"
        case .walkingAsymmetryPercentage:       return "figure.mixed.cardio" // TODO: - 심볼 수정하기
        case .walkingSpeed:                     return "figure.walk.motion"
        case .walkingDoubleSupportPercentage:   return "percent" // TODO: - 심볼 수정하기
        }
    }

    ///
    var unit: HKUnit {
        switch self {
        case .distanceWalkingRunning:         return HKUnit.meterUnit(with: .kilo)
        case .appleExerciseTime:              return HKUnit.minute()
        case .activeEnergyBurned:             return HKUnit.kilocalorie()
        case .basalEnergyBurned:              return HKUnit.kilocalorie()
        case .walkingStepLength:              return HKUnit.meterUnit(with: .centi)
        case .walkingAsymmetryPercentage:     return HKUnit.percent()
        case .walkingSpeed:                   return HKUnit.meter().unitDivided(by: .hour()) // KPH
        case .walkingDoubleSupportPercentage: return HKUnit.percent()
        }
    }

    ///
    var unitString: String {
        unit.unitString
    }

    ///
    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .distanceWalkingRunning:           return .distanceWalkingRunning
        case .appleExerciseTime:                return .appleExerciseTime
        case .activeEnergyBurned:               return .activeEnergyBurned
        case .basalEnergyBurned:                return .basalEnergyBurned
        case .walkingStepLength:                return .walkingStepLength
        case .walkingAsymmetryPercentage:       return .walkingAsymmetryPercentage
        case .walkingSpeed:                     return .walkingSpeed
        case .walkingDoubleSupportPercentage:   return .walkingDoubleSupportPercentage
        }
    }
}

extension DashboardCardStack {

    ///
    enum Unit {
        ///
        case unit(HealthKit.HKUnit)
        ///
        case custom(String)

        ///
        var symbol: String {
            switch self {
            case .unit(let unit):     return unit.unitString
            case .custom(let string): return string
            }
        }
    }
}

