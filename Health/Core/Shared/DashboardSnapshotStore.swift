//
//  DashboardSnapshotStore.swift
//  Health
//
//  Created by Seohyun Kim on 8/24/25.
//

import WidgetKit

struct DashboardSnapshotStore {
	static func saveAndNotify(_ s: HealthDashboardSnapshot) {
		SharedStore.saveCodable(s, forKey: SharedStore.Key.dashboardSnapshotV1)
		WidgetCenter.shared.reloadTimelines(ofKind: WidgetIDs.health)
	}
}

