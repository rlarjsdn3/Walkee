//
//  SharedStore.swift
//  Health
//
//  Created by Nat Kim on 8/23/25.
//

import Foundation

enum SharedStore {
	private static let storage = UserDefaultsWrapper(suitName: "group.com.seohyun.walking")
	
	private static let snapshotKey = "dashboard.snapshot"
	
	static func save<T: Codable>(_ value: T, for keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Data?>>) {
		guard let data = try? JSONEncoder().encode(value) else { return }
		storage.set(forKey: keyPath, value: data)
	}
	
	static func load<T: Codable>(_ type: T.Type, for keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Data?>>) -> T? {
		let data: Data? = storage.get(forKey: keyPath)
		guard let data else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
	
	static func remove(for keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Data?>>) {
		storage.remove(forKey: keyPath)
	}
}
