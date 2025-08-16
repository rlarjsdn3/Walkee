//
//  DistrictModels.swift
//  Health
//
//  Created by Seohyun Kim on 8/16/25.
//

import Foundation

struct District: Codable {
	let code: String
	let name: String
	let children: [District]?
}

/// 앱 번들에서 JSON을 1회 로드 + 이름 > 상위 시/도 인덱스 구성
enum DistrictLoader {
	@MainActor static let shared = DistrictLoaderImpl()
}

final class DistrictLoaderImpl {
	private(set) var provinces: [District] = []
	/// “시/군/구/동/읍/면” → 상위 시/도 이름
	private(set) var nameToProvince: [String: String] = [:]
	/// “시/도” 이름 Set
	private(set) var provinceNames: Set<String> = []

	init() { loadFromBundle() }

	private func loadFromBundle() {
		guard
			let url = Bundle.main.url(
				forResource: "korea-administrative-district",
				withExtension: "json"
			),
			let data = try? Data(contentsOf: url),
			let roots = try? JSONDecoder().decode([District].self, from: data)
		else {
			assertionFailure("korea-administrative-district.json 로드 실패")
			return
		}

		provinces = roots
		buildIndexes()
	}

	private func buildIndexes() {
		provinceNames.removeAll()
		nameToProvince.removeAll()

		for p in provinces {
			provinceNames.insert(p.name)
			index(province: p, provinceName: p.name)
		}
	}

	private func index(province: District, provinceName: String) {
		// 시/도 자신도 name > province 매핑에 넣어둠(검색 편의)
		nameToProvince[province.name] = provinceName

		guard let children = province.children else { return }
		for c in children {
			// 시/군/구/자치구
			nameToProvince[c.name] = provinceName
			// 하위 읍/면/동까지 재귀
			indexAllDescendants(node: c, provinceName: provinceName)
		}
	}

	private func indexAllDescendants(node: District, provinceName: String) {
		guard let children = node.children else { return }
		for c in children {
			nameToProvince[c.name] = provinceName
			indexAllDescendants(node: c, provinceName: provinceName)
		}
	}
}
