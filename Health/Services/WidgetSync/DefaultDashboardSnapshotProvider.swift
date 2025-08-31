//
//  DefaultDashboardSnapshotProvider.swift
//  Health
//
//  Created by Seohyun Kim on 8/24/25.
//
import Foundation
import UIKit
import WidgetKit
import HealthKit
/**
 대시보드 스냅샷을 생성하는 기본 구현체.

 `DefaultDashboardSnapshotProvider`는 HealthKit과 CoreData 목표 데이터를 기반으로
 사용자의 걸음 수, 거리, 운동 시간, 칼로리, 주간 평균 등을 종합한
 `HealthDashboardSnapshot`을 반환한다.

 ## 주요 기능
 - 오늘 하루 걸음 수, 이동 거리, 운동 시간, 활동 칼로리 수집
 - 7일 평균 걸음 수 계산 (누락일은 0으로 처리)
 - 목표 걸음 수(CoreData 저장값) 반영
 - Foreground 상태에서 CoreMotion delta를 빠르게 합산해 즉시 스냅샷 갱신 가능

 ## 사용 예시
 ```swift
 let provider = DefaultDashboardSnapshotProvider()
 let today = Date()

 Task {
	 do {
		 let snapshot = try await provider.makeSnapshot(for: today)
		 print("오늘 걸음 수:", snapshot.stepsToday)
	 } catch {
		 print("스냅샷 생성 실패:", error)
	 }
 }
 */
@MainActor
protocol DashboardSnapshotProvider {
	func makeSnapshot(for date: Date) async throws -> HealthDashboardSnapshot
}

private func valueOrZero(_ op: @escaping () async throws -> Double) async throws -> Double {
	do { return try await op() }
	// 권한 미결정/거부, 데이터 없음은 모두 0으로
	catch let e as HKError where e.code == .errorAuthorizationNotDetermined { return 0 }
	catch let e as HKError where e.code == .errorAuthorizationDenied { return 0 }
	catch let e as HKError where e.code == .errorNoData { return 0 }
	// 혹시 NSError 코드로 들어오는 경우 안전망
	catch let e as NSError where e.domain == HKError.errorDomain && (e.code == 5 || e.code == 11) { return 0 }
	catch { throw error } // 그 외 에러만 전달
}

final class DefaultDashboardSnapshotProvider: DashboardSnapshotProvider {
	@Injected private var health: HealthService
	@Injected private var goals: GoalStepCountViewModel
	/// 지정한 날짜 구간의 스냅샷을 만든다.
	/// - Parameter date: 스냅샷 기준 날짜
	/// - Returns: `HealthDashboardSnapshot` (걸음 수, 거리, 칼로리 등 집계)
	/// - Throws: HealthKit 접근 권한 거부, 통계 조회 실패 시 에러 발생
	@MainActor
	func makeSnapshot(for date: Date) async throws -> HealthDashboardSnapshot {
		let start = date.startOfDay()
		let end = date.endOfDay()
		
		// 1) 병렬 수집
		async let stepsValue: Double = try await valueOrZero {
			try await self.health.fetchStatistics(
				for: .stepCount, from: start, to: end,
				options: .cumulativeSum, unit: .count()
			).value
		}
		
		async let distMeter: Double = try await valueOrZero {
			try await self.health.fetchStatistics(
				for: .distanceWalkingRunning, from: start, to: end,
				options: .cumulativeSum, unit: .meter()
			).value
		}

		async let exMinute: Double = try await valueOrZero {
			try await self.health.fetchStatistics(
				for: .appleExerciseTime, from: start, to: end,
				options: .cumulativeSum, unit: .minute()
			).value
		}

		async let activeKcal: Double = try await valueOrZero {
			try await self.health.fetchStatistics(
				for: .activeEnergyBurned, from: start, to: end,
				options: .cumulativeSum, unit: .kilocalorie()
			).value
		}
		
		// 2) 7일 평균 (예: HealthKit로 계산하는 경우)
		let weeklyAvg = try await weeklyAverageSteps(endingOn: end)
		
		// 3) async let 읽기 > 반드시 try await
		let step = try await stepsValue
		let dM = try await distMeter
		let exMin = try await exMinute
		let kcal = try await activeKcal
		
		// 4) 목표 걸음수(CoreData)
		let goal = goals.goalStepCount(for: end) ?? 10_000
		
		// 5) 스냅샷 반환
		return HealthDashboardSnapshot(
			stepsToday: Int(step),
			goalSteps: Int(goal),
			distanceKm: dM / 1000.0,
			exerciseMinute: Int(exMin),
			activeKcal: Int(kcal),
			weeklyAvgSteps: weeklyAvg
		)
	}
	
	

	
	/// 같은 날 기존 스냅샷에 실시간 걸음 delta를 반영해 즉시 반환.
	/// - Parameters:
	///   - date: 스냅샷 기준 날짜
	///   - delta: CoreMotion에서 측정된 추가 걸음 수
	/// - Returns: 델타가 합산된 스냅샷
	func makeSnapshot(
		for date: Date,
		addStepDelta delta: Int
	) async throws -> HealthDashboardSnapshot {
		// 1) 같은 날의 기존 스냅샷이 있으면 거기에 더해서 즉시 반환(빠름)
		if var s = SharedStore.loadCodable(HealthDashboardSnapshot.self,
										   forKey: SharedStore.Key.dashboardSnapshotV1),
		   Calendar.current.isDate(s.generatedAt, inSameDayAs: date) {
			let newSteps = max(0, s.stepsToday + max(0, delta))
			s = HealthDashboardSnapshot(
				generatedAt: s.generatedAt,
				lastUpdated: .now,
				stepsToday: newSteps,
				goalSteps: s.goalSteps,
				distanceKm: s.distanceKm,
				exerciseMinute: s.exerciseMinute,
				activeKcal: s.activeKcal,
				weeklyAvgSteps: s.weeklyAvgSteps
			)
			return s
		}
		
		// 2) 없으면 HealthKit으로 새로 만들고 delta 더해서 반환
		var fresh = try await makeSnapshot(for: date)
		fresh = HealthDashboardSnapshot(
			generatedAt: fresh.generatedAt,
			lastUpdated: .now,
			stepsToday: max(0, fresh.stepsToday + max(0, delta)),
			goalSteps: fresh.goalSteps,
			distanceKm: fresh.distanceKm,
			exerciseMinute: fresh.exerciseMinute,
			activeKcal: fresh.activeKcal,
			weeklyAvgSteps: fresh.weeklyAvgSteps
		)
		return fresh
	}
	
	/// 최근 7일 평균 걸음 수를 계산.
	/// - Parameter endOfToday: 기준이 되는 오늘 날짜
	/// - Returns: 반올림된 7일 평균 걸음 수
	private func weeklyAverageSteps(endingOn endOfToday: Date) async throws -> Int {
		let cal = Calendar.current
		let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -6, to: endOfToday.startOfDay())!)
		let end   = endOfToday.endOfDay()
		
		let collection = try await health.fetchStatisticsCollection(
			for: .stepCount,
			from: start,
			to: end,
			options: .cumulativeSum,
			interval: DateComponents(day: 1),
			unit: .count()
		)
		
		// 일자→값 맵 (HK는 값 없는 날을 생략할 수 있음)
		var byDay: [Date: Double] = [:]
		for item in collection {
			byDay[item.startDate.startOfDay()] = item.value
		}
		
		// 정확히 7칸 채우기(누락일 0)
		var total = 0.0
		for offset in 0..<7 {
			let day = cal.date(byAdding: .day, value: offset, to: start)!
			total += byDay[day.startOfDay()] ?? 0.0
		}
		
		// 반올림으로 통일 (대시보드와 동일)
		return Int((total / 7.0).rounded(.toNearestOrAwayFromZero))
	}
}

// MARK: - Date helpers
private extension Date {
	func startOfDay() -> Date { Calendar.current.startOfDay(for: self) }
	func endOfDay() -> Date {
		let calendar = Calendar.current
		return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: self))!
	}
}
