//
//  DashboardSnapshotStore.swift
//  Health
//
//  Created by Seohyun Kim on 8/24/25.
//

import WidgetKit

// 앱 전용, 스냅샷 생성 → 저장 → 리로드
enum DashboardSnapshotStore {
	static func saveAndNotify(_ s: HealthDashboardSnapshot) {
		SharedStore.saveCodable(s, forKey: SharedStore.Key.dashboardSnapshotV1)
		WidgetCenter.shared.reloadTimelines(ofKind: WidgetIDs.health)
	}
	@MainActor
	static func updateFromHealthKit(
		date: Date = .now,
		provider: DashboardSnapshotProvider = DefaultDashboardSnapshotProvider()
	) async {
		do {
			// HealthKit/코어데이터
			let snap = try await provider.makeSnapshot(for: date)
			// App Group JSON 저장
			SharedStore.saveDashboard(snap)
			WidgetCenter.shared.reloadTimelines(ofKind: WidgetIDs.health)
			print("🟢 updateFromHealthKit saved: steps=\(snap.stepsToday)")
		} catch {
			print("🔴 updateFromHealthKit error:", error)
		}
	}
}

