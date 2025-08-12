//
//  HealthDataViewModel.swift
//  Health
//
//  Created by juks86 on 8/12/25.
//

import Foundation

final class HealthDataViewModel: ObservableObject {

    // 의존성 주입
    @Injected(.healthService) private var healthService: HealthService

    // 싱글톤 패턴
    @MainActor static let shared = HealthDataViewModel()
    private init() {}

    /// 일주일간의 건강 데이터를 비동기로 가져옵니다
    /// 현재는 더미 데이터를 반환하며, 나중에 실제 HealthKit 데이터로 교체 예정
    /// - Returns: 일주일간의 걸음수, 거리 등이 포함된 WeeklyHealthData
    func getWeeklyHealthData() async -> WeeklyHealthData {

        // 일주일 기간 계산
        let calendar = Calendar.current
        let today = Date()

        let weekday = calendar.component(.weekday, from: today)  // 오늘이 무슨 요일인지 확인
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2   // 이번주 월요일 찾기
        let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!  // 이번 주 월요일
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!  // 이번 주 일요일

        // 기본 더미 데이터 (건강 데이터 없을 때)
        var dailySteps = [10, 10, 10, 10, 10, 10, 10]        // 걸음수 배열
        var dailyDistances = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  // 거리 배열

        print("📊 7일간 실제 걸음수 + 거리 데이터 가져오기 시작!")

        // 🚶‍♂️ 오늘부터 지난 6일까지 총 7일 데이터 가져오기
        for dayOffset in 0...6 {  // 0=오늘, 1=어제, 2=그저께, ..., 6=6일전
            do {
                // 각 날짜 계산 (오늘에서 dayOffset일 빼기)
                let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)!

                // 해당 날짜의 하루 범위 설정 (00:00:00 ~ 23:59:59)
                let dayStart = calendar.startOfDay(for: targetDate)  // 자정
                let dayEnd = calendar.date(byAdding: .second, value: 86399, to: dayStart)!  // 23:59:59

                // 걸음수 먼저 가져오기
                let stepsData = try await healthService.fetchStatistics(
                    for: .stepCount,           // 걸음수 타입
                    from: dayStart,            // 해당 날짜 00:00:00부터
                    to: dayEnd,                // 해당 날짜 23:59:59까지
                    options: .cumulativeSum,   // 하루 총 걸음수
                    unit: .count()             // 개수 단위
                )

                // 거리 가져오기
                let distanceData = try await healthService.fetchStatistics(
                    for: .distanceWalkingRunning,  // 걷기+달리기 거리 타입
                    from: dayStart,                // 해당 날짜 00:00:00부터
                    to: dayEnd,                    // 해당 날짜 23:59:59까지
                    options: .cumulativeSum,       // 하루 총 거리
                    unit: .meterUnit(with: .kilo)  // 킬로미터 단위
                )

                // 걸음수와 거리 값 추출
                let daySteps = Int(stepsData.value.isNaN ? 0 : stepsData.value)
                let dayDistance = distanceData.value.isNaN ? 0.0 : distanceData.value

                //해당 날짜가 무슨 요일인지 확인해서 배열 위치 찾기
                let targetWeekday = calendar.component(.weekday, from: targetDate)  // 해당 날짜 요일
                let arrayIndex = targetWeekday == 1 ? 6 : targetWeekday - 2  // 배열 인덱스로 변환 (월=0, 화=1, ..., 일=6)

                // 해당 요일 위치에 실제 데이터 넣기
                dailySteps[arrayIndex] = daySteps
                dailyDistances[arrayIndex] = dayDistance

                // 몇일전인지와 요일 이름 출력
                let dayNames = ["월", "화", "수", "목", "금", "토", "일"]
                let dayName = dayNames[arrayIndex]
                let dayDescription = dayOffset == 0 ? "오늘" : "\(dayOffset)일전"

                print("\(dayDescription)(\(dayName)요일): \(daySteps.formatted())걸음, \(String(format: "%.1f", dayDistance))km")

            } catch {
                print("\(dayOffset)일전 데이터 가져오기 실패: \(error)")
                // 실패해도 계속 진행 (해당 날짜는 0으로 남음)
            }
        }

        print("최종 걸음수 배열 (월화수목금토일): \(dailySteps)")
        print("최종 거리 배열 (월화수목금토일): \(dailyDistances.map { String(format: "%.1f", $0) + "km" })")

        // 결과 반환
        return WeeklyHealthData(
            weeklyTotalSteps: dailySteps.reduce(0, +),           // 7일 총 걸음수 (실제 데이터)
            weeklyTotalDistance: dailyDistances.reduce(0, +),    // 7일 총 거리 (실제 데이터)
            dailySteps: dailySteps,                              // 월화수목금토일 실제 걸음수
            weekStartDate: weekStart,                            // 월요일 날짜
            weekEndDate: weekEnd                                 // 일요일 날짜
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
