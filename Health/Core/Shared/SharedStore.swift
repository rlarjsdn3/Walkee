//
//  SharedStore.swift
//  Health
//
//  Created by Seohyun Kim on 8/23/25.
//

import Foundation

enum SharedStore {
	// NOTE: - 반드시 suiteID에 본인의 group.com.myWidgetSuiteName.walking으로 바꿔주세요.
	// 앱그룹의 번들 아이디는 중복이 되면 아예 빌드가 안되는 문제도 있습니다.
	static let suiteID = "group.com.myWidgetSuiteName.walking"
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
