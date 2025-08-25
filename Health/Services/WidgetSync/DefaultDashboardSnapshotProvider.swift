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
		
		// 3) async let 읽기 → 반드시 try await
		let step = try await stepsValue
		let dM = try await distMeter
		let exMin = try await exMinute
		let kcal = try await activeKcal
		
		// 4) 목표 걸음수(CoreData)
		let goal = goals.goalStepCount(for: end) ?? 10_000
		
		// 5) 스냅샷 반환 (여기엔 await 불필요)
		return HealthDashboardSnapshot(
			stepsToday: Int(step),
			goalSteps: Int(goal),
			distanceKm: dM / 1000.0,
			exerciseMinute: Int(exMin),
			activeKcal: Int(kcal),
			weeklyAvgSteps: weeklyAvg
		)
	}
	
	

	
	// 증분 반영 버전 (전경 CoreMotion 전용)
	func makeSnapshot(for date: Date, addStepDelta delta: Int) async throws -> HealthDashboardSnapshot {
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
	
	/// 오늘을 포함한 최근 7일 평균(반올림). HealthKit 컬렉션에 빠진 날은 0으로 채운다.
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
		let c = Calendar.current
		return c.date(byAdding: DateComponents(day: 1, second: -1), to: c.startOfDay(for: self))!
	}
}
