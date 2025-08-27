//
//  TestHealthService.swift
//  HealthTests
//
//  Created by Nat Kim on 8/27/25.
//

import Foundation
import HealthKit
@testable import Health

/// HealthService 테스트 스텁. 실제 HealthKit 접근 없이 즉시 성공/기본값만 반환.
final class TestHealthService: HealthService {
	func requestAuthorization() async throws -> Bool { true }
	func checkHasAnyReadPermission() async -> Bool { true }
	func checkHasReadPermission(for identifier: HKQuantityTypeIdentifier) async -> Bool { true }

	func fetchSamples(
		for identifier: HKQuantityTypeIdentifier,
		from startDate: Date,
		to endDate: Date,
		limit: Int,
		sortDescriptors: [NSSortDescriptor]?,
		unit: HKUnit
	) async throws -> [HKData] { [] }

	func fetchStatistics(
		for identifier: HKQuantityTypeIdentifier,
		from startDate: Date,
		to endDate: Date,
		options: HKStatisticsOptions,
		unit: HKUnit
	) async throws -> HKData {
		HKData(startDate: startDate, endDate: endDate, value: .zero)
	}

	func fetchStatisticsCollection(
		for identifier: HKQuantityTypeIdentifier,
		from startDate: Date,
		to endDate: Date,
		options: HKStatisticsOptions,
		interval intervalComponents: DateComponents,
		unit: HKUnit
	) async throws -> [HKData] { [] }
}
