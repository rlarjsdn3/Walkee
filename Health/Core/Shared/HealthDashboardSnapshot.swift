//
//  HealthDashboardSnapshot.swift
//  Health
//
//  Created by Seohyun Kim on 8/23/25.
//

import Foundation

struct HealthDashboardSnapshot: Codable, Sendable, Equatable {
	let generatedAt: Date
	let lastUpdated: Date      // 마지막 저장 시각
	let stepsToday: Int
	let goalSteps: Int
	let distanceKm: Double
	let exerciseMinute: Int
	let activeKcal: Int
	let weeklyAvgSteps: Int
	
	init(
		generatedAt: Date = .now,
		lastUpdated: Date = .now,
		stepsToday: Int,
		goalSteps: Int,
		distanceKm: Double,
		exerciseMinute: Int,
		activeKcal: Int,
		weeklyAvgSteps: Int
	) {
		self.generatedAt = generatedAt
		self.lastUpdated = lastUpdated
		self.stepsToday = stepsToday
		self.goalSteps = goalSteps
		self.distanceKm = distanceKm
		self.exerciseMinute = exerciseMinute
		self.activeKcal = activeKcal
		self.weeklyAvgSteps = weeklyAvgSteps
	}
}


extension HealthDashboardSnapshot {
	// 표시용 포맷
	var stepsTodayText: String { stepsToday.formatted(.number.grouping(.automatic)) }
	var goalStepsText: String { goalSteps.formatted(.number.grouping(.automatic)) }
	var weeklyAvgText: String { weeklyAvgSteps.formatted(.number.grouping(.automatic)) }
	var distanceText: String { distanceKm.formatted(.number.precision(.fractionLength(0...1))) }
	var exerciseMinuteText: String { exerciseMinute.formatted(.number) }
	var activeKcalText: String { activeKcal.formatted(.number) }
}

// 미리보기 mock data / 값이 없을 때의 데이터
extension HealthDashboardSnapshot {
	static let empty = HealthDashboardSnapshot(
		stepsToday: 0,
		goalSteps: 0,
		distanceKm: 0,
		exerciseMinute: 0,
		activeKcal: 0,
		weeklyAvgSteps: 0
	)
	
	static let previewMock = HealthDashboardSnapshot(
		stepsToday: 5_000,
		goalSteps: 7_000,
		distanceKm: 3.0,
		exerciseMinute: 70,
		activeKcal: 300,
		weeklyAvgSteps: 1_952
	)
}
