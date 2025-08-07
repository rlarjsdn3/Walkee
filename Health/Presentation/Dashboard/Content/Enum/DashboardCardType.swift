//
//  DashboardCardType.swift
//  Health
//
//  Created by 김건우 on 8/7/25.
//

import HealthKit
import UIKit

///
enum DashboardCardType: CaseIterable {

    ///
    case walkingStepLength
    ///
    case walkingAsymmetryPercentage
    ///
    case walkingSpeed
    ///
    case walkingDoubleSupportPercentage
}

extension DashboardCardType {

    ///
    var title: String? {
        switch self {
        case .walkingStepLength:                return "보행 보폭"
        case .walkingAsymmetryPercentage:       return "보행 비대칭성"
        case .walkingSpeed:                     return "보행 속도"
        case .walkingDoubleSupportPercentage:   return "이중 지지 시간"
        }
    }

    ///
    var unit: HKUnit {
        switch self {
        case .walkingStepLength:              return HKUnit.meterUnit(with: .centi)
        case .walkingAsymmetryPercentage:     return HKUnit.percent()
        case .walkingSpeed:                   return HKUnit.meter().unitDivided(by: .second()) // m/s
        case .walkingDoubleSupportPercentage: return HKUnit.percent()
        }
    }

    ///
    var unitString: String {
        switch self {
        case .walkingStepLength:              return "cm"
        case .walkingAsymmetryPercentage:     return "%"
        case .walkingSpeed:                   return "m/s"
        case .walkingDoubleSupportPercentage: return "%"
        }
    }

    ///
    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .walkingStepLength:                return .walkingStepLength
        case .walkingAsymmetryPercentage:       return .walkingAsymmetryPercentage
        case .walkingSpeed:                     return .walkingSpeed
        case .walkingDoubleSupportPercentage:   return .walkingDoubleSupportPercentage
        }
    }

    ///
    func status(_ value: Double, age: Int) -> DashboardCardType.GaitStatus {
        switch self {
        case .walkingStepLength:                return status(forStepLength: value, age: age)
        case .walkingAsymmetryPercentage:       return status(forAsymmetryPercentage: value, age: age)
        case .walkingSpeed:                     return status(forWalkingSpeed: value, age: age)
        case .walkingDoubleSupportPercentage:   return status(forAsymmetryPercentage: value, age: age)
        }
    }

    ///
    func status(forStepLength centi: Double, age: Int) -> DashboardCardType.GaitStatus {
        switch age {
        case (..<20):   return evaluateStatusGreaterThan(centi, normal: 65, caution: 55) // 10대
        case (20..<30): return evaluateStatusGreaterThan(centi, normal: 65, caution: 55) // 20대
        case (30..<40): return evaluateStatusGreaterThan(centi, normal: 63, caution: 53) // 30대
        case (40..<50): return evaluateStatusGreaterThan(centi, normal: 60, caution: 50) // 40대
        case (50..<60): return evaluateStatusGreaterThan(centi, normal: 58, caution: 48) // 50대
        case (60..<70): return evaluateStatusGreaterThan(centi, normal: 55, caution: 45) // 60대
        default: return evaluateStatusGreaterThan(centi, normal: 50, caution: 40)        // 70대
        }
    }

    ///
    func status(forAsymmetryPercentage percentage: Double, age: Int) -> DashboardCardType.GaitStatus {
        evaluateStatusLessThan(percentage, normal: 0.10, caution: 0.19) // 전 연령 공통
    }

    ///
    func status(forWalkingSpeed mps: Double, age: Int) -> DashboardCardType.GaitStatus {
        switch age {
        case (..<20):   return evaluateStatusGreaterThan(mps, normal: 1.4, caution: 1.2)   // 10대
        case (20..<30): return evaluateStatusGreaterThan(mps, normal: 1.4, caution: 1.2)   // 20대
        case (30..<40): return evaluateStatusGreaterThan(mps, normal: 1.35, caution: 1.15) // 30대
        case (40..<50): return evaluateStatusGreaterThan(mps, normal: 1.3, caution: 1.1)   // 40대
        case (50..<60): return evaluateStatusGreaterThan(mps, normal: 1.25, caution: 1.0)  // 50대
        case (60..<70): return evaluateStatusGreaterThan(mps, normal: 1.1, caution: 0.9)   // 60대
        default: return evaluateStatusGreaterThan(mps, normal: 1.0, caution: 0.8)          // 70대
        }
    }

    ///
    func status(forDoubleSupportPercentage percentage: Double, age: Int) -> DashboardCardType.GaitStatus {
        switch age {
        case (..<20):   return evaluateStatusLessThan(percentage, normal: 0.20, caution: 0.25)   // 10대
        case (20..<30): return evaluateStatusLessThan(percentage, normal: 0.20, caution: 0.25)   // 20대
        case (30..<40): return evaluateStatusLessThan(percentage, normal: 0.22, caution: 0.28)   // 30대
        case (40..<50): return evaluateStatusLessThan(percentage, normal: 0.24, caution: 0.30)   // 40대
        case (50..<60): return evaluateStatusLessThan(percentage, normal: 0.26, caution: 0.32)   // 50대
        case (60..<70): return evaluateStatusLessThan(percentage, normal: 0.28, caution: 0.34)   // 60대
        default: return evaluateStatusLessThan(percentage, normal: 0.30, caution: 0.36)          // 70대
        }
    }
}

extension DashboardCardType {

    enum GaitStatus {
        ///
        case normal
        ///
        case caution
        ///
        case warning

        ///
        var systemName: String {
            switch self {
            case .normal:   return "checkmark"
            case .caution:  return "exclamationmark.triangle.fill"
            case .warning:  return "exclamationmark.circle.fill"
            }
        }

        ///
        var backgroundColor: UIColor {
            switch self {
            case .normal:   return .systemGreen
            case .caution:  return .systemYellow
            case .warning:  return .systemRed
            }
        }
    }
}

fileprivate extension DashboardCardType {

    func evaluateStatusGreaterThan(
        _ value: Double,
        normal: Double,
        caution: Double
    ) -> DashboardCardType.GaitStatus {
        if value >= normal { return .normal }
        else if value >= caution { return .caution }
        else { return .warning }
    }

    func evaluateStatusLessThan(
        _ value: Double,
        normal: Double,
        caution: Double
    ) -> DashboardCardType.GaitStatus {
        if value <= normal { return .normal }
        else if value <= caution { return .caution }
        else { return .warning }
    }
}
