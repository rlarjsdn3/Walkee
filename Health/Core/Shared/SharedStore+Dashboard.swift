//
//  SharedStore+Dashboard.swift
//  Health
//
//  Created by Nat Kim on 8/23/25.
//

import Foundation

extension SharedStore {
	static func saveDashboard(_ snap: HealthDashboardSnapshot) {
		saveCodable(snap, forKey: Key.dashboardSnapshotV1)
	}

	static func loadDashboard() -> HealthDashboardSnapshot? {
		loadCodable(HealthDashboardSnapshot.self, forKey: Key.dashboardSnapshotV1)
	}
}
