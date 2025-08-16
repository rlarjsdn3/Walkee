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
	let code: String
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
	static func loadJSON(from bundle: Bundle = .main,
						 filename: String = "korea-administrative-district",
						 ext: String = "json") -> [District] {
		guard
			let url = bundle.url(forResource: filename, withExtension: ext),
			let data = try? Data(contentsOf: url),
			let roots = try? JSONDecoder().decode([District].self, from: data)
		else {
			assertionFailure("⚠️ \(filename).\(ext) 로드 실패(타겟 멤버십 확인)")
			return []
		}
		return roots
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
