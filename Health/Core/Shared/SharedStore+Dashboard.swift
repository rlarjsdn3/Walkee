//
//  SharedStore+Dashboard.swift
//  Health
//
//  Created by Nat Kim on 8/23/25.
//

import Foundation

extension SharedStore {
	static func saveDashboard(_ snap: HealthDashboardSnapshot) {
		save(snap, for: \.dashboardSnapshotDataV1)
	}
	
	static func loadDashboard() -> HealthDashboardSnapshot? {
		load(HealthDashboardSnapshot.self, for: \.dashboardSnapshotDataV1)
	}
}
