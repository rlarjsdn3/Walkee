//
//  HealthDataViewModel.swift
//  Health
//
//  Created by juks86 on 8/12/25.
//

import Foundation

final class HealthDataViewModel: ObservableObject {
    
    // 의존성 주입 (나중에 추가)
    //@Injected(.healthService) private var healthService: HealthService
    
    // 싱글톤 패턴
    @MainActor static let shared = HealthDataViewModel()
    private init() {}
    
    /// 일주일간의 건강 데이터를 비동기로 가져옵니다
    /// 현재는 더미 데이터를 반환하며, 나중에 실제 HealthKit 데이터로 교체 예정
    /// - Returns: 일주일간의 걸음수, 거리 등이 포함된 WeeklyHealthData
    func getWeeklyHealthData() async -> WeeklyHealthData {
        
        let calendar = Calendar.current
        let today = Date()
        
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        
        let dailySteps = [8500, 12000, 6800, 9500, 11200, 15000, 7300]
        let dailyDistances = [6.2, 8.8, 5.0, 7.1, 8.3, 11.0, 5.4]
        
        return WeeklyHealthData(
            weeklyTotalSteps: dailySteps.reduce(0, +),
            weeklyTotalDistance: dailyDistances.reduce(0, +),
            dailySteps: dailySteps,
            weekStartDate: weekStart,
            weekEndDate: weekEnd
        )
    }
    
    /// 한 달간의 건강 데이터를 비동기로 가져옵니다 (지난달 비교 데이터 포함)
    /// 현재는 더미 데이터를 반환하며, 나중에 실제 HealthKit 데이터로 교체 예정
    /// - Returns: 이번달과 지난달 걸음수, 거리, 칼로리가 포함된 MonthlyHealthData
    func getMonthlyHealthData() async -> MonthlyHealthData {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let calendar = Calendar.current
        let today = Date()
        
        let thisMonthStart = calendar.dateInterval(of: .month, for: today)!.start
        let thisMonthEnd = calendar.dateInterval(of: .month, for: today)!.end
        
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!
        let lastMonthStart = calendar.dateInterval(of: .month, for: lastMonth)!.start
        let lastMonthEnd = calendar.dateInterval(of: .month, for: lastMonth)!.end
        
        let thisMonthTotalSteps = 265000
        let thisMonthTotalDistance = 210.5
        let thisMonthTotalCalories = 8500
        
        let lastMonthTotalSteps = 275000
        let lastMonthTotalDistance = 195.2
        let lastMonthTotalCalories = 7800
        
        return MonthlyHealthData(
            monthlyTotalSteps: thisMonthTotalSteps,
            monthlyTotalDistance: thisMonthTotalDistance,
            monthlyTotalCalories: thisMonthTotalCalories,
            monthStartDate: thisMonthStart,
            monthEndDate: thisMonthEnd,
            previousMonthSteps: lastMonthTotalSteps,
            previousMonthDistance: lastMonthTotalDistance,
            previousMonthCalories: lastMonthTotalCalories
        )
    }
}
