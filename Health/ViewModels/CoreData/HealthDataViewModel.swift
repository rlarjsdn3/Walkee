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

    /// 일주일간의 건강 데이터를 비동기로 가져옵니다
    /// - Returns: 일주일간의 걸음수, 거리 등이 포함된 WeeklyHealthData
    func getWeeklyHealthData() async -> WeeklyHealthData {

        // 일주일 기간 계산
        let today = Date()

        guard let weekStart = today.startOfWeek(),
              let weekEnd = today.endOfWeek() else {
            // 주간 범위 계산 실패 시 더미 데이터 반환
            return WeeklyHealthData(
                weeklyTotalSteps: 70,
                weeklyTotalDistance: 0.0,
                dailySteps: [10, 10, 10, 10, 10, 10, 10],
                weekStartDate: today,
                weekEndDate: today
            )
        }

        // 기본 더미 데이터 (건강 데이터 없을 때)
        var dailySteps = [0, 0, 0, 0, 0, 0, 0]        // 걸음수 배열
        var dailyDistances = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  // 거리 배열

        // 오늘부터 지난 6일까지 총 7일 데이터 가져오기
        for dayOffset in 0...6 {  // 0=오늘, 1=어제, 2=그저께, ..., 6=6일전
            do {
                // 각 날짜 계산 (오늘로부터 6일 전까지의 날짜 계산)
                guard let targetDate = today.addingDays(-dayOffset) else { continue }
                let (dayStart, dayEnd) = targetDate.rangeOfDay()

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
                let targetWeekday = Calendar.current.component(.weekday, from: targetDate)  // 해당 날짜 요일
                let arrayIndex = targetWeekday == 1 ? 6 : targetWeekday - 2  // 배열 인덱스로 변환 (월=0, 화=1, ..., 일=6)

                // 해당 요일 위치에 실제 데이터 넣기
                dailySteps[arrayIndex] = daySteps
                dailyDistances[arrayIndex] = dayDistance

                // 몇일전인지와 요일 이름 출력
                let dayNames = ["월", "화", "수", "목", "금", "토", "일"]
                let dayName = dayNames[arrayIndex]
                let dayDescription = dayOffset == 0 ? "오늘" : "\(dayOffset)일전"

            } catch {
                // 실패해도 계속 진행 (해당 날짜는 0으로 남음)
            }
        }

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
    /// 이번 달과 지난 달 데이터를 비교해서 MonthlyHealthData 구조체로 반환
    func getMonthlyHealthData() async -> MonthlyHealthData {

        let today = Date()

        // 날짜 계산
        guard let thisMonthStart = today.startOfMonth(),
              let thisMonthEnd = today.endOfMonth() else {
            // 이번 달 범위 계산 실패 시 더미 데이터 반환
            return createResult(
                thisMonth: (steps: 0, distance: 0.0, calories: 0.0),
                lastMonth: (steps: 0, distance: 0.0, calories: 0.0),
                thisMonthStart: today,
                thisMonthEnd: today
            )
        }

        guard let lastMonthDate = today.addingMonths(-1),
              let lastMonthStart = lastMonthDate.startOfMonth(),
              let lastMonthEnd = lastMonthDate.endOfMonth() else {
            // 지난 달 범위 계산 실패 시 더미 데이터 반환
            return createResult(
                thisMonth: (steps: 0, distance: 0.0, calories: 0.0),
                lastMonth: (steps: 0, distance: 0.0, calories: 0.0),
                thisMonthStart: thisMonthStart,
                thisMonthEnd: thisMonthEnd
            )
        }

        // 날짜 범위 출력
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // 더미 데이터 (기본값)
        let dummyThisMonth = (steps: 0, distance: 0.0, calories: 0.0)
        let dummyLastMonth = (steps: 0, distance: 0.0, calories: 0.0)

        let hasPermission = await healthService.checkHasAnyReadPermission()

        if !hasPermission {
            print("HealthKit 권한 없음 - 더미 데이터 사용")
            return createResult(thisMonth: dummyThisMonth, lastMonth: dummyLastMonth,
                                thisMonthStart: thisMonthStart, thisMonthEnd: thisMonthEnd)
        }

        // 실제 데이터 가져오기
        async let thisMonthData = fetchMonthData(from: thisMonthStart, to: thisMonthEnd, monthName: "이번 달")
        async let lastMonthData = fetchMonthData(from: lastMonthStart, to: lastMonthEnd, monthName: "지난 달")

        let (thisMonth, lastMonth) = await (thisMonthData, lastMonthData)

        // 데이터가 있으면 실제 데이터 사용
        if thisMonth.steps > 0 || thisMonth.distance > 0 || thisMonth.calories > 0 {
            return createResult(thisMonth: thisMonth, lastMonth: lastMonth,
                                thisMonthStart: thisMonthStart, thisMonthEnd: thisMonthEnd)
        } else {
            print("실제 데이터 없음 - 더미 데이터 사용")
            return createResult(thisMonth: dummyThisMonth, lastMonth: dummyLastMonth,
                                thisMonthStart: thisMonthStart, thisMonthEnd: thisMonthEnd)
        }
    }

    /// 특정 기간의 월간 건강 데이터를 HealthKit에서 가져오는 함수
    /// - Parameters:
    ///   - startDate: 데이터를 가져올 시작 날짜 (예: 8월 1일 00:00:00)
    ///   - endDate: 데이터를 가져올 종료 날짜 (예: 8월 31일 23:59:59)
    ///   - monthName: 로그 출력용 달 이름 ("이번 달" 또는 "지난 달")
    /// - Returns: (걸음수, 거리, 칼로리) 튜플
    private func fetchMonthData(from startDate: Date, to endDate: Date, monthName: String) async -> (steps: Int, distance: Double, calories: Double) {
        do {
            // 걸음수, 거리, 칼로리 가져오기
            let stepsTask = try await healthService.fetchStatistics(
                for: .stepCount, from: startDate, to: endDate,
                options: .cumulativeSum, unit: .count()
            )

            let distanceTask = try await healthService.fetchStatistics(
                for: .distanceWalkingRunning, from: startDate, to: endDate,
                options: .cumulativeSum, unit: .meterUnit(with: .kilo)
            )

            let caloriesTask = try await healthService.fetchStatistics(
                for: .activeEnergyBurned, from: startDate, to: endDate,
                options: .cumulativeSum, unit: .kilocalorie()
            )

            let (stepsData, distanceData, caloriesData) = (stepsTask, distanceTask, caloriesTask)

            // 안전한 값 추출(NaN 체크)
            let steps = Int(max(0, stepsData.value.isNaN ? 0 : stepsData.value))
            let distance = max(0.0, distanceData.value.isNaN ? 0.0 : distanceData.value)
            let calories = max(0.0, caloriesData.value.isNaN ? 0.0 : caloriesData.value)

            return (steps: steps, distance: distance, calories: calories)

        } catch {
            return (steps: 0, distance: 0.0, calories: 0.0)
        }
    }

    /// 가져온 월간 데이터를 MonthlyHealthData 구조체로 변환하는 함수
    /// - Parameters:
    ///   - thisMonth: 이번 달 데이터 (걸음수, 거리, 칼로리)
    ///   - lastMonth: 지난 달 데이터 (걸음수, 거리, 칼로리)
    ///   - thisMonthStart: 이번 달 시작 날짜
    ///   - thisMonthEnd: 이번 달 종료 날짜
    /// - Returns: 완성된 MonthlyHealthData 구조체
    private func createResult(
        thisMonth: (steps: Int, distance: Double, calories: Double),
        lastMonth: (steps: Int, distance: Double, calories: Double),
        thisMonthStart: Date,
        thisMonthEnd: Date
    ) -> MonthlyHealthData {

        // 변화량 계산 및 출력
        let stepsDiff = thisMonth.steps - lastMonth.steps
        let distanceDiff = thisMonth.distance - lastMonth.distance
        let caloriesDiff = thisMonth.calories - lastMonth.calories

        return MonthlyHealthData(
            monthlyTotalSteps: thisMonth.steps,
            monthlyTotalDistance: thisMonth.distance,
            monthlyTotalCalories: thisMonth.calories,
            monthStartDate: thisMonthStart,
            monthEndDate: thisMonthEnd,
            previousMonthSteps: lastMonth.steps,
            previousMonthDistance: lastMonth.distance,
            previousMonthCalories: lastMonth.calories
        )
    }
}
