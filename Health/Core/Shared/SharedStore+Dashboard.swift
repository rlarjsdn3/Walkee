//
//  SharedStore+Dashboard.swift
//  Health
//
//  Created by Seohyun Kim on 8/23/25.
//

import WidgetKit

extension SharedStore {
	static func saveDashboard(_ snap: HealthDashboardSnapshot) {
		saveCodable(snap, forKey: Key.dashboardSnapshotV1)
		// 저장 시 위젯 갱신 신호
		WidgetCenter.shared.reloadTimelines(ofKind: WidgetIDs.health)
	}

	static func loadDashboard() -> HealthDashboardSnapshot? {
		loadCodable(HealthDashboardSnapshot.self, forKey: Key.dashboardSnapshotV1)
	}
	
	static func updateDashboard(_ mutate: (inout HealthDashboardSnapshot) -> Void) {
		
	}
}
