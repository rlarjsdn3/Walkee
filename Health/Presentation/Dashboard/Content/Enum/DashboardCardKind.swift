//
//  DashboardCardKind.swift
//  Health
//
//  Created by 김건우 on 8/7/25.
//

import HealthKit
import UIKit

///
enum DashboardCardKind: CaseIterable {

    ///
    case walkingStepLength
    ///
    case walkingAsymmetryPercentage
    ///
    case walkingSpeed
    ///
    case walkingDoubleSupportPercentage
}

extension DashboardCardKind {

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
}

extension DashboardCardKind {

    ///
    func status(_ value: Double, age: Int) -> DashboardCardKind.GaitStatus {
        switch self {
        case .walkingStepLength:                return status(forStepLength: value, age: age)
        case .walkingAsymmetryPercentage:       return status(forAsymmetryPercentage: value, age: age)
        case .walkingSpeed:                     return status(forWalkingSpeed: value, age: age)
        case .walkingDoubleSupportPercentage:   return status(forDoubleSupportPercentage: value, age: age)
        }
    }

    ///
    func status(forStepLength centi: Double, age: Int) -> DashboardCardKind.GaitStatus {
        let thresholds: [Double] = stepLengthThresholdValues(age: age)
        let normal = thresholds[2]  // 주어진 연령대에 해당하는 주의(Caution) 범위의 첫 번째 값 (lowerBound)
        let caution = thresholds[1] // 주어진 연령대에 해당하는 주의(Caution) 범위의  마지막 값 (upperBound)

        // higer is better
        return evaluateStatusGreaterThan(centi, normal: normal, caution: caution)
    }

    ///
    func status(forWalkingSpeed mps: Double, age: Int) -> DashboardCardKind.GaitStatus {
        let thresholds: [Double] = walkingSpeedThresholdValue(age: age)
        let normal = thresholds[2]  // 주어진 연령대에 해당하는 주의(Caution) 범위의 첫 번째 값 (lowerBound)
        let caution = thresholds[1] // 주어진 연령대에 해당하는 주의(Caution) 범위의  마지막 값 (upperBound)

        // higer is better
        return evaluateStatusGreaterThan(mps, normal: normal, caution: caution)
    }

    ///
    func status(forAsymmetryPercentage percentage: Double, age: Int) -> DashboardCardKind.GaitStatus {
        let thresholds: [Double] = asymmetryPercentageThresholdValue(age: age)
        let normal = thresholds[1]  // 주어진 연령대에 해당하는 주의(Caution) 범위의 첫 번째 값 (lowerBound)
        let caution = thresholds[2] // 주어진 연령대에 해당하는 주의(Caution) 범위의  마지막 값 (upperBound)

        // lower is better
        return evaluateStatusLessThan(percentage, normal: normal, caution: caution) // 전 연령 공통
    }

    ///
    func status(forDoubleSupportPercentage percentage: Double, age: Int) -> DashboardCardKind.GaitStatus {
        let thresholds: [Double] = doubleSupportPercentageThresholdValue(age: age)
        let normal = thresholds[1]  // 주어진 연령대에 해당하는 주의(Caution) 범위의 첫 번째 값 (lowerBound)
        let caution = thresholds[2] // 주어진 연령대에 해당하는 주의(Caution) 범위의  마지막 값 (upperBound)

        // lower is better
        return evaluateStatusLessThan(percentage, normal: normal, caution: caution)
    }
}

extension DashboardCardKind {

    ///
    func thresholdValues(age: Int) -> [Double] {
        switch self {
        case .walkingStepLength:                return stepLengthThresholdValues(age: age)
        case .walkingAsymmetryPercentage:       return asymmetryPercentageThresholdValue(age: age)
        case .walkingSpeed:                     return walkingSpeedThresholdValue(age: age)
        case .walkingDoubleSupportPercentage:   return doubleSupportPercentageThresholdValue(age: age)
        }
    }

    ///
    func stepLengthThresholdValues(age: Int) -> [Double] {
        switch age {  // higher is better
        case (..<20):   return [45, 55, 65, 75] // 10대
        case (20..<30): return [45, 55, 65, 75] // 20대
        case (30..<40): return [43, 53, 63, 73] // 30대
        case (40..<50): return [40, 50, 60, 70] // 40대
        case (50..<60): return [38, 48, 58, 68] // 50대
        case (60..<70): return [35, 45, 55, 65] // 60대
        default: return [30, 40, 50, 60]        // 70대
        }
    }

    ///
    func walkingSpeedThresholdValue(age: Int) -> [Double] {
        switch age {  // higher is better
        case (..<20):   return [1.0, 1.2, 1.4, 1.6]     // 10대
        case (20..<30): return [1.0, 1.2, 1.4, 1.6]     // 20대
        case (30..<40): return [0.95, 1.15, 1.35, 1.55] // 30대
        case (40..<50): return [0.9, 1.1, 1.3, 1.5]     // 40대
        case (50..<60): return [0.75, 1.0, 1.25, 1.5]   // 50대
        case (60..<70): return [0.7, 0.9, 1.1, 1.3]     // 60대
        default: return [0.6, 0.8, 1.0, 1.2]            // 70대
        }
    }

    ///
    func asymmetryPercentageThresholdValue(age: Int) -> [Double] {
        [0.01, 0.10, 0.19, 0.28] // lower is better
    }

    ///
    func doubleSupportPercentageThresholdValue(age: Int) -> [Double] {
        switch age { // lower is better
        case (..<20):   return [0.15, 0.2, 0.25, 0.3]   // 10대
        case (20..<30): return [0.15, 0.2, 0.25, 0.3]   // 20대
        case (30..<40): return [0.16, 0.22, 0.28, 0.34] // 30대
        case (40..<50): return [0.18, 0.24, 0.30, 0.36] // 40대
        case (50..<60): return [0.2, 0.26, 0.32, 0.38]  // 50대
        case (60..<70): return [0.22, 0.28, 0.34, 0.4]  // 60대
        default: return [0.24, 0.3, 0.36, 0.42]         // 70대
        }
    }
}

extension DashboardCardKind {

    ///
    var higherIsBetter: Bool {
        switch self {
        case .walkingSpeed, .walkingStepLength:                            return true
        case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage: return false
        }
    }
}


extension DashboardCardKind {

    enum GaitStatus: String {
        ///
        case normal  = "정상"
        ///
        case caution = "주의"
        ///
        case warning = "경고"

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

        ///
        var secondaryBackgroundColor: UIColor {
            backgroundColor.withAlphaComponent(0.1)
        }
    }
}

extension DashboardCardKind: Hashable {
}

fileprivate extension DashboardCardKind {

    func evaluateStatusGreaterThan(
        _ value: Double,
        normal: Double,
        caution: Double
    ) -> DashboardCardKind.GaitStatus {
        if value >= normal { return .normal }
        else if value >= caution { return .caution }
        else { return .warning }
    }

    func evaluateStatusLessThan(
        _ value: Double,
        normal: Double,
        caution: Double
    ) -> DashboardCardKind.GaitStatus {
        if value <= normal { return .normal }
        else if value <= caution { return .caution }
        else { return .warning }
    }
}

