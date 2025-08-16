//
//  PrivacyService.swift
//  Health
//
//  Created by Seohyun Kim on 8/17/25.
//

import Foundation
import NaturalLanguage

/// 사용자가 입력한 텍스트(예: 질문 메시지)에서 **개인정보(주소, 이름, 주민등록번호, 이메일 등)** 를
/// 마스킹 처리하여 외부 API(AI 서버 등)로 전송될 때 안전하게 보호하는 역할을 합니다.
/// 프라이버시 전처리(이름/ 주민번호/ 전화번호/ 주소)를 담당하는 서비스
///
/// 구현체는 내부적으로 행정구역 데이터(`DistrictDB`)와
/// `AddressRegionClassifier` 등을 활용하여 주소를 `시/도` 수준으로만 축약하거나,
/// 이메일/주민등록번호 등은 별도의 규칙으로 가공합니다
enum RRNMaskStyle {
	case monthBoldStars
	case monthKeepHyphen
}

struct PrivacyService {
	static func maskSensitiveInfo(in text: String) -> String {
		var replacements: [(range: NSRange, replacement: String)] = []

		// 각 항목별 마스킹 대상 추출
		replacements += findNameReplacements(in: text)
		replacements += findRRNReplacements(in: text)
		replacements += findPhoneReplacements(in: text)
		replacements += findAddressReplacements(in: text)

		// 충돌 방지를 위해 뒤에서부터 교체
		replacements.sort { $0.range.location > $1.range.location }

		var result = text
		for r in replacements {
			if let swiftRange = Range(r.range, in: result) {
				result.replaceSubrange(swiftRange, with: r.replacement)
			}
		}
		return result
	}

	// MARK: - 이름 마스킹
	static func findNameReplacements(in text: String) -> [(NSRange, String)] {
		var results: [(NSRange, String)] = []

		let patterns = [
			#"(?<=내 이름은\s)([가-힣])[가-힣]{1,2}"#,
			#"(?<=나는\s)([가-힣])[가-힣]{1,2}"#,
			#"(?<=저는\s)([가-힣])[가-힣]{1,2}"#,
			#"(?<=이름은\s)([가-힣])[가-힣]{1,2}"#,
			#"(?<=제 이름은\s)([가-힣])[가-힣]{1,2}"#,
			#"([가-힣])[가-힣]{1,2}(?=(고|야|입니다|이고|이에요|이예요|입니다\.|입니다!|입니다,))"#
		]

		for pattern in patterns {
			if let regex = try? NSRegularExpression(pattern: pattern) {
				let range = NSRange(text.startIndex..<text.endIndex, in: text)
				regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
					guard let match = match,
						  let nameRange = match.range(at: 1) as NSRange? else { return }
					let original = (text as NSString).substring(with: nameRange)
					results.append((match.range, "\(original)모씨"))
				}
			}
		}
		return results
	}

	// MARK: - 주민등록번호 마스킹
	static func findRRNReplacements(in text: String) -> [(NSRange, String)] {
		let pattern = #"(?<!\d)(\d{2})(\d{2})(\d{2})[-]?(?:\s)?([1-8])(\d{6})(?!\d)"#
		guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

		let range = NSRange(text.startIndex..<text.endIndex, in: text)
		var results: [(NSRange, String)] = []

		regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
			guard let match = match else { return }
			let yy = (text as NSString).substring(with: match.range(at: 1))
			let mm = (text as NSString).substring(with: match.range(at: 2))
			let dd = (text as NSString).substring(with: match.range(at: 3))
			let g  = (text as NSString).substring(with: match.range(at: 4))

			if isValidDateYYMMDD(yy: yy, mm: mm, dd: dd) {
				results.append((match.range, "**\(mm)**-\(g)******"))
			}
		}
		return results
	}

	static func isValidDateYYMMDD(yy: String, mm: String, dd: String) -> Bool {
		guard let m = Int(mm), let d = Int(dd), (1...12).contains(m) else { return false }
		let days = [31,28,31,30,31,30,31,31,30,31,30,31]
		return (1...days[m - 1]).contains(d)
	}

	// MARK: - 전화번호 (간단한 예시)
	static func findPhoneReplacements(in text: String) -> [(NSRange, String)] {
		let pattern = #"(01[016789])-?(\d{3,4})-?(\d{4})"#
		guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

		let range = NSRange(text.startIndex..<text.endIndex, in: text)
		var results: [(NSRange, String)] = []

		regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
			guard let match = match else { return }
			results.append((match.range, "010-****-****"))
		}
		return results
	}

	// MARK: - 주소 마스킹 (도시 + 구만 남기기)
	static func findAddressReplacements(in text: String) -> [(NSRange, String)] {
		let db = DistrictDB.shared
		let sorted = db.nameToProvince.keys.sorted { $0.count > $1.count }

		for keyword in sorted {
			guard let province = db.nameToProvince[keyword],
				  let range = text.range(of: keyword) else { continue }

			// "경기도 부천시" 형태로 축약
			let replacement = "\(province) \(keyword)"

			let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
			return [(nsRange, replacement)]
		}
		return []
	}
}

// MARK: - 정규식 치환 헬퍼 (캡처 그룹 배열 접근)
private extension String {
	/// 정규식 패턴으로 매칭된 구간을 **캡처 그룹 배열**을 이용해 커스텀 빌더로 교체합니다.
	///
	/// - Parameters:
	///   - pattern: 정규식 패턴
	///   - options: 정규식 옵션
	///   - builder: 캡처 그룹(`m[0]` 전체, `m[1...]` 그룹들)을 받아 치환 문자열을 반환하는 클로저
	/// - Returns: 치환이 적용된 문자열
	func replacingOccurrences(of pattern: String,
							  options: NSRegularExpression.Options = [],
							  with builder: ([String]) -> String) -> String {
		guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return self }
		let nsrange = NSRange(startIndex..<endIndex, in: self)
		var result = self
		for match in regex.matches(in: self, options: [], range: nsrange).reversed() {
			var groups: [String] = []
			for i in 0..<match.numberOfRanges {
				let r = match.range(at: i)
				if let rr = Range(r, in: self) { groups.append(String(self[rr])) }
				else { groups.append("") }
			}
			let replacement = builder(groups)
			if let rr = Range(match.range, in: result) {
				result.replaceSubrange(rr, with: replacement)
			}
		}
		return result
	}
}
