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
	/// 항상 시/도만 남김 (예: “서울특별시”, “경기도”)
	case provinceOnly
}

//@MainActor
struct AddressRegionClassifier {
	/// 입력 텍스트에서 상위 "시/도" 명칭을 추출
	static func detectProvince(in text: String) -> String? {
		let db = DistrictDB.shared
		
		for key in db
			.nameToProvince
			.keys
			.sorted(by: { $0.count > $1.count }) where text.contains(key) {
			return db.nameToProvince[key]
		}
		
		for province in db.provinceNames where text.contains(province) { return province }
		return nil
	}

	/// 주소 마스킹 결과 문자열 (현재 정책: 시/도만 남김)
	static func maskedAddress(
		from text: String,
		style: AddressMaskStyle = .provinceOnly
	) -> String? {
		guard let province = detectProvince(in: text) else { return nil }
		switch style {
		case .provinceOnly:
			return province
		}
	}
}
