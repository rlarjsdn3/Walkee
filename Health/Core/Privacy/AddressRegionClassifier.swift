//
//  AddressRegionClassifier.swift
//  Health
//
//  Created by Seohyun Kim on 8/16/25.
//

import Foundation

/// 사용자의 상세 주소 문자열에서 시/도 단위로 축약된 행정구역을 분류합니다.
///
/// - 입력: 자유롭게 작성된 주소 문자열 (예: "서울특별시 강남구 역삼동 ...").
/// - 처리: 내부적으로 `DistrictIndex`를 사용하여 문자열 내에서 가장 가까운 상위 시/도를 탐색.
/// - 출력: 시/도 이름만 반환하여 개인정보 노출을 방지.
///
/// 이 코드는 `PrivacyService` 내부에서 상세 주소 마스킹 시 활용됩니다.
enum AddressMaskStyle {
	/// 항상 시/도만 남김 (예: "서울시", "경기도")
	case provinceOnly
	/// 시/도 + 구/군(예: "서울특별시 강남구")
	case provinceWithDistrict
}

struct AddressRegionClassifier {
	
	// MARK: - 시/도 별칭 매핑 (사용자 표현 → JSON 표준명)
	private static let provinceAliases: [String: String] = [
		"서울": "서울특별시",
		"서울시": "서울특별시",
		"부산": "부산광역시",
		"부산시": "부산광역시",
		"대구": "대구광역시",
		"대구시": "대구광역시",
		"인천": "인천광역시",
		"인천시": "인천광역시",
		"광주": "광주광역시",
		"광주시": "광주광역시",
		"대전": "대전광역시",
		"대전시": "대전광역시",
		"울산": "울산광역시",
		"울산시": "울산광역시",
		"세종": "세종특별자치시",
		"세종시": "세종특별자치시",
		"경기": "경기도",
		"강원": "강원특별자치도",
		"강원도": "강원특별자치도",
		"충북": "충청북도",
		"충남": "충청남도",
		"전북": "전북특별자치도",
		"전남": "전라남도",
		"경북": "경상북도",
		"경남": "경상남도",
		"제주": "제주특별자치도",
		"제주도": "제주특별자치도"
	]
	
	// MARK: - 주소 감지 결과 구조체
	struct AddressDetectionResult {
		let originalText: String        // 원본에서 사용된 시/도 표현
		let standardProvince: String    // 표준 시/도명
		let city: String?              // 구/군명 (있는 경우)
		let range: Range<String.Index> // 주소 전체 범위
	}
	
	/// 입력 텍스트에서 상위 "시/도" 명칭을 추출
	static func detectProvince(in text: String) -> String? {
		let db = DistrictDB.shared
		
		// 1. 별칭부터 먼저 체크 (길이순)
		for (alias, standardName) in provinceAliases.sorted(by: { $0.key.count > $1.key.count }) {
			if text.contains(alias) {
				return standardName
			}
		}
		
		// 2. JSON 데이터의 nameToProvince에서 찾기
		for key in db.nameToProvince.keys.sorted(by: { $0.count > $1.count }) {
			if text.contains(key) {
				return db.nameToProvince[key]
			}
		}
		
		// 3. 표준 시/도명에서 직접 찾기
		for province in db.provinceNames.sorted(by: { $0.count > $1.count }) {
			if text.contains(province) {
				return province
			}
		}
		
		return nil
	}
	
	/// 주소 마스킹 결과 문자열 (현재 정책: 시/도만 남김)
	static func maskedAddress(
		from text: String,
		style: AddressMaskStyle = .provinceOnly
	) -> String? {
		guard let result = detectDetailedAddress(in: text) else { return nil }
		
		switch style {
		case .provinceOnly:
			return result.originalText
			
		case .provinceWithDistrict:
			if let city = result.city {
				return "\(result.originalText) \(city)"
			} else {
				return result.originalText
			}
		}
	}
	
	// MARK: - PrivacyService용 주소 마스킹 메서드 (메인 진입점)
	
	/// PrivacyService에서 사용하는 주소 마스킹 처리
	/// 이 메서드가 주소 마스킹의 메인 진입점입니다.
	static func findAddressReplacements(in text: String) -> [(NSRange, String)] {
		print("[AddressClassifier] 입력 텍스트: \(text)")
		
		guard let result = detectDetailedAddress(in: text) else {
			print("[AddressClassifier] 주소를 찾을 수 없음")
			return []
		}
		
		let nsRange = NSRange(result.range, in: text)
		let maskedAddress = generateMaskedAddress(from: result, in: text)
		
		print("[AddressClassifier] 최종 마스킹 결과: '\(maskedAddress)'")
		return [(nsRange, maskedAddress)]
	}
	
	// MARK: - 상세 주소 감지 (내부 핵심 로직)
	/// 텍스트에서 주소를 상세 분석하여 DetectionResult 반환
	private static func detectDetailedAddress(in text: String) -> AddressDetectionResult? {
		let db = DistrictDB.shared
		
		// 1단계: 시/도 찾기 (별칭 우선)
		var foundProvince: String?
		var foundProvinceRange: Range<String.Index>?
		var originalProvinceText: String?
		
		// 별칭부터 먼저 체크 (길이 순으로 정렬하여 긴 것부터)
		let sortedAliases = provinceAliases.keys.sorted { $0.count > $1.count }
		for alias in sortedAliases {
			if let range = text.range(of: alias) {
				foundProvince = provinceAliases[alias]
				foundProvinceRange = range
				originalProvinceText = alias
				//print("[AddressClassifier] 별칭 매칭: '\(alias)' → '\(foundProvince!)'")
				break
			}
		}
		
		// 별칭에서 못찾으면 JSON 데이터에서 찾기
		if foundProvince == nil {
			let sortedKeys = db.nameToProvince.keys.sorted { $0.count > $1.count }
			for key in sortedKeys {
				if let range = text.range(of: key) {
					foundProvince = db.nameToProvince[key]
					foundProvinceRange = range
					originalProvinceText = key
					//print("[AddressClassifier] JSON 키 매칭: '\(key)' → '\(foundProvince!)'")
					break
				}
			}
		}
		
		// 마지막으로 표준명에서 찾기
		if foundProvince == nil {
			let sortedProvinces = db.provinceNames.sorted { $0.count > $1.count }
			for province in sortedProvinces {
				if let range = text.range(of: province) {
					foundProvince = province
					foundProvinceRange = range
					originalProvinceText = province
					print("🔍 [AddressClassifier] 표준명 매칭: '\(province)'")
					break
				}
			}
		}
		
		guard let province = foundProvince,
			  let provinceRange = foundProvinceRange,
			  let originalText = originalProvinceText else {
			return nil
		}
		
		// 2단계: 해당 시/도의 구/군 찾기
		var foundCity: String?
		if let provinceData = findProvinceData(province: province, in: db) {
			let sortedCities = provinceData.sorted { $0.count > $1.count }
			
			for city in sortedCities {
				if text.contains(city) {
					foundCity = city
					//print("[AddressClassifier] 구/군 매칭: '\(city)'")
					break
				}
			}
		}
		
		// 3단계: 주소 범위 결정
		let addressRange = determineAddressRange(
			text: text,
			provinceRange: provinceRange
		)
		
		let addressText = String(text[addressRange])
		print("[AddressClassifier] 주소 범위: '\(addressText)'")
		
		return AddressDetectionResult(
			originalText: originalText,
			standardProvince: province,
			city: foundCity,
			range: addressRange
		)
	}
	
	/// 주소의 정확한 범위를 결정 (PromptFilteringKeywords 활용)
	private static func determineAddressRange(
		text: String,
		provinceRange: Range<String.Index>
	) -> Range<String.Index> {
		let startIndex = provinceRange.lowerBound
		var endIndex = text.endIndex
		
		// 시/도 뒤에서부터 탐색
		let afterProvince = text[provinceRange.upperBound...]
		print("[AddressClassifier] 시/도 뒤 텍스트: '\(afterProvince)'")
		
		// 1. PromptFilteringKeywords로 질문 시작 지점 찾기 (최우선)
		let questionKeywords = PromptFilteringKeywords.getPromptIntentionKeywords()
		for keyword in questionKeywords {
			if let keywordRange = afterProvince.range(of: keyword) {
				let potentialEnd = keywordRange.lowerBound
				if potentialEnd < endIndex {
					endIndex = potentialEnd
					//print("[AddressClassifier] 질문 키워드로 종료: '\(keyword)'")
					break
				}
			}
		}
		
		// 2. 주소 끝 키워드로 추가 확인 (질문 키워드가 없을 때만)
		if endIndex == text.endIndex {
			let addressEndKeywords = PromptFilteringKeywords.getAddressTerminationKeywords()
			for keyword in addressEndKeywords {
				if let keywordRange = afterProvince.range(of: keyword) {
					let potentialEnd = keywordRange.upperBound
					if potentialEnd < endIndex {
						endIndex = potentialEnd
						//print("[AddressClassifier] 주소 끝 키워드로 확장: '\(keyword)'")
					}
				}
			}
		}
		
		return startIndex..<endIndex
	}
	
	/// 마스킹된 주소 문자열 생성 (질문 의도에 따른 차등 마스킹)
	private static func generateMaskedAddress(
		from result: AddressDetectionResult,
		in text: String
	) -> String {
		// 질문 의도 분석
		let intentions = PromptFilteringKeywords.analyzePromptIntention(in: text)
		//print("[AddressClassifier] 질문 의도: \(intentions)")
		
		// 의료 관련 질문이면 시/도만
		if intentions.contains(.promptHealthcare) {
			return result.originalText
		} else {
			// 일반 질문은 시/도 + 구/군 (있는 경우에만)
			if let city = result.city {
				return "\(result.originalText) \(city)"
			} else {
				return result.originalText
			}
		}
	}
	
	// MARK: - 헬퍼 메서드들
	
	/// 시/도에 해당하는 구/군 데이터 찾기 (JSON 데이터 활용)
	private static func findProvinceData(province: String, in db: DistrictIndex) -> [String]? {
		// JSON 데이터에서 해당 시/도의 구/군 목록 반환
		let cityKeywords = db.nameToProvince.compactMap { (city, prov) -> String? in
			return prov == province && city != province ? city : nil
		}
		return cityKeywords.isEmpty ? nil : cityKeywords
	}
	
	/// 별칭을 표준명으로 변환
	static func getStandardProvinceName(for alias: String) -> String? {
		return provinceAliases[alias]
	}
	
	/// 모든 별칭 목록 반환
	static func getAllProvinceAliases() -> [String: String] {
		return provinceAliases
	}
	
	// MARK: - 공개 유틸리티 메서드들
	
	/// 텍스트에 주소가 포함되어 있는지 확인
	static func containsAddress(in text: String) -> Bool {
		return detectProvince(in: text) != nil
	}
	
	/// 주소 감지 결과를 반환 (테스트/디버깅용)
	static func analyzeAddress(in text: String) -> AddressDetectionResult? {
		return detectDetailedAddress(in: text)
	}
}
