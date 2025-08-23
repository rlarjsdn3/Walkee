//
//  HealthDashboardSnapshot.swift
//  Health
//
//  Created by Nat Kim on 8/23/25.
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
