//
//  DistrictModels.swift
//  Health
//
//  Created by Seohyun Kim on 8/16/25.
//
import Foundation

/// 대한민국 행정구역(District) 모델과 인덱스 Loader를 정의
///
/// - `District`: 시/도, 시/군/구, 읍/면/동 등 행정 단위를 표현하는 구조체.
/// - `DistrictIndex`: 불변 인덱스로, 특정 지명에서 상위 시/도를 빠르게 찾을 수 있습니다.
/// - `DistrictIndexFactory`: JSON으로 로드된 `District` 배열을 기반으로 인덱스를 생성합니다.
/// - `DistrictJSONLoader`: 앱 번들에 포함된 행정구역 JSON 파일(`korea-administrative-district.json`)을 로드합니다.
///
/// 이 코드는 개인정보 마스킹 처리에서 **상세 주소 → 시/도 단위로 축약**하기 위해 사용됩니다.
// MARK: - Model
struct District: Codable, Sendable {
	let code: String?
	let name: String
	let children: [District]?
}

struct DistrictIndex: Sendable {
	let provinces: [District]
	let nameToProvince: [String: String]
	let provinceNames: Set<String>
}

// MARK: - 전역 불변 캐시 (앱 생애주기 내 1회 생성)
enum DistrictDB {
	static let shared: DistrictIndex = {
		let roots = loadJSON()
		return makeIndex(from: roots)
	}()
}

// MARK: - JSON 로딩
private extension DistrictDB {
	struct CosmosRoot: Codable {
		let name: String?
		let version: String?
		let url: String?
		let data: [[String: [String]]]
	}

	static func loadJSON(
		from bundle: Bundle = .main,
		filename: String = "korea-administrative-district",
		ext: String = "json"
	) -> [District] {

		// 1) 파일/데이터 로드까지만 보장
		guard
			let url = bundle.url(forResource: filename, withExtension: ext),
			let data = try? Data(contentsOf: url)
		else {
			assertionFailure("⚠️ \(filename).\(ext) 파일을 찾지 못했어요(타겟 멤버십/경로 확인).")
			return []
		}

		// 2) 기존 포맷([District]) 먼저 시도
		if let roots = try? JSONDecoder().decode([District].self, from: data) {
			return roots
		}

		// 3) cosmosfarm 포맷 시도 (루트 객체 + data 배열)
		if let root = try? JSONDecoder().decode(CosmosRoot.self, from: data) {
			let provinces: [District] = root.data.compactMap { dict in
				guard let (provinceName, cities) = dict.first else { return nil }
				let children = cities.map { District(code: nil, name: $0, children: nil) }
				return District(code: nil, name: provinceName, children: children)
			}
			return provinces
		}

		// 4) 둘 다 실패한 경우에만 크래시
		assertionFailure("⚠️ \(filename).\(ext) 디코딩 실패(스키마 불일치/인코딩 확인).")
		return []
	}
}

// MARK: - 인덱스 팩토리
private extension DistrictDB {
	static func makeIndex(from roots: [District]) -> DistrictIndex {
		var map: [String: String] = [:]
		var provincesSet: Set<String> = []

		func index(province: District, pname: String) {
			map[province.name] = pname
			province.children?.forEach {
				map[$0.name] = pname
				indexAll(node: $0, pname: pname)
			}
		}
		
		func indexAll(node: District, pname: String) {
			node.children?.forEach {
				map[$0.name] = pname
				indexAll(node: $0, pname: pname)
			}
		}

		for p in roots {
			provincesSet.insert(p.name)
			index(province: p, pname: p.name)
		}

		return DistrictIndex(
			provinces: roots,
			nameToProvince: map,
			provinceNames: provincesSet
		)
	}
}
