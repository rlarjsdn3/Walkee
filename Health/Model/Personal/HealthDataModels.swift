//
//  HealthDataModels.swift
//  Health
//
//  Created by juks86 on 8/12/25.
//

import Foundation
import UIKit

/// 일주일간의 헬스 데이터
struct WeeklyHealthData {
    let weeklyTotalSteps: Int           // 일주일 총 걸음 수
    let weeklyTotalDistance: Double     // 일주일 총 거리 (km)
    let dailySteps: [Int]              // 7일간 일별 걸음 수 [월, 화, 수, 목, 금, 토, 일]
    let weekStartDate: Date            // 주의 시작일 (월요일)
    let weekEndDate: Date              // 주의 종료일 (일요일)
}

/// 한 달간의 헬스 데이터
struct MonthlyHealthData {
    let monthlyTotalSteps: Int         // 한 달 총 걸음 수
    let monthlyTotalDistance: Double   // 한 달 총 거리 (km)
    let monthlyTotalCalories: Int      // 한 달 총 소모 칼로리
    let monthStartDate: Date           // 월의 시작일
    let monthEndDate: Date             // 월의 종료일

    let previousMonthSteps: Int        // 지난달 총 걸음 수
    let previousMonthDistance: Double  // 지난달 총 거리
    let previousMonthCalories: Int     // 지난달 총 칼로리

    // 비교 계산 프로퍼티
    var stepsDifference: Int {
        return monthlyTotalSteps - previousMonthSteps
    }

    var distanceDifference: Double {
        return monthlyTotalDistance - previousMonthDistance
    }

    var caloriesDifference: Int {
        return monthlyTotalCalories - previousMonthCalories
    }

    var stepsChangeType: ChangeType {
        if stepsDifference > 0 { return .increase }
        else if stepsDifference < 0 { return .decrease }
        else { return .same }
    }

    var distanceChangeType: ChangeType {
        if distanceDifference > 0 { return .increase }
        else if distanceDifference < 0 { return .decrease }
        else { return .same }
    }

    var caloriesChangeType: ChangeType {
        if caloriesDifference > 0 { return .increase }
        else if caloriesDifference < 0 { return .decrease }
        else { return .same }
    }
}

//변화 유형 열거형
enum ChangeType {
    case increase   // 증가 ▲
    case decrease   // 감소 ▼
    case same       // 동일

    var symbol: String {
        switch self {
        case .increase: return "▲"
        case .decrease: return "▼"
        case .same: return "="
        }
    }

    var color: UIColor {
        switch self {
        case .increase: return .systemRed
        case .decrease: return .systemBlue
        case .same: return .systemRed
        }
    }
}
