//
//  SharedStore.swift
//  Health
//
//  Created by Seohyun Kim on 8/23/25.
//

import Foundation

enum SharedStore {
	private static let suiteID = "group.com.seohyun.walking"
	
	private static var ud: UserDefaults {
		guard let u = UserDefaults(suiteName: suiteID) else {
			fatalError("App Group not configured: \(suiteID)")
		}
		return u
	}
	
	enum Key {
		/// 대시보드/위젯 스냅샷(버전 명시)
		static let dashboardSnapshotV1 = "dashboard.snapshot.v1"
	}
	
	// MARK: - Codable 저장/로드
	static func saveCodable<T: Codable>(_ value: T, forKey key: String) {
		guard let data = try? JSONEncoder().encode(value) else { return }
		ud.set(data, forKey: key)
	}
	
	static func loadCodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
		guard let data = ud.data(forKey: key) else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
	
	static func remove(_ key: String) {
		ud.removeObject(forKey: key)
	}
}
