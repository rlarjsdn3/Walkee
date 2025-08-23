//
//  ForegroundMotionAggregator.swift
//  Health
//
//  Created by Nat Kim on 8/23/25.
//

import CoreMotion
import HealthKit

/// 전경(포어그라운드)에서 CoreMotion 델타를 합산해 위젯 스냅샷을 보강
final class ForegroundMotionAggregator {

	private let pedometer = CMPedometer()
	private var baseSnapshot: HealthDashboardSnapshot?   // 전경 진입 시점의 HK 스냅샷
	private var accumulatedSteps: Int = 0
	private var isRunning = false

	/// 전경 진입 시, 오늘자 HealthKit 스냅샷을 넘겨주세요.
	/// - Important: `todaySnapshot.stepsToday`는 "현재 시점의 HK 누적"이어야 함.
	func start(with todaySnapshot: HealthDashboardSnapshot) {
		guard CMPedometer.isStepCountingAvailable() else { return }
		guard !isRunning else { return }

		isRunning = true
		baseSnapshot = todaySnapshot
		accumulatedSteps = 0

		// 현재 시각 이후 증가분만 델타로 받음
		pedometer.startUpdates(from: Date()) { [weak self] data, _ in
			guard let self,
				  let d = data,
				  let base = self.baseSnapshot
			else { return }

			// 현재 세션 이후 증가한 걸음(증분)
			let delta = d.numberOfSteps.intValue
			self.accumulatedSteps = max(0, delta)

			// 델타를 더한 최신 스냅샷 생성
			let merged = HealthDashboardSnapshot(
				generatedAt: base.generatedAt,
				lastUpdated: Date(),                         // 마지막 갱신 시각
				stepsToday: max(0, base.stepsToday + delta), // HK 누적 + 델타
				goalSteps: base.goalSteps,
				distanceKm: base.distanceKm,                 // 거리/운동/에너지는 HK 재계산 타이밍에 갱신
				exerciseMinute: base.exerciseMinute,
				activeKcal: base.activeKcal,
				weeklyAvgSteps: base.weeklyAvgSteps
			)

			// App Group 저장 → 위젯 갱신
			SharedStore.saveCodable(merged, forKey: SharedStore.Key.dashboardSnapshotV1)
			WidgetBridge.reloadAll()
		}
	}

	/// 전경 이탈/일시정지 시 호출
	func stop() {
		guard isRunning else { return }
		pedometer.stopUpdates()
		isRunning = false
		accumulatedSteps = 0
	}

	/// (선택) 백그라운드 HK 재계산 이후, 새 HK 스냅샷을 받아 베이스를 갈아끼울 때 사용
	func resetBase(with todaySnapshot: HealthDashboardSnapshot) {
		baseSnapshot = todaySnapshot
		accumulatedSteps = 0
	}
}
