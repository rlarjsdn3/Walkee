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
protocol PrivacyService {
	/// Alan AI API 전송 직전 한 번 호출해 안전 텍스트로 변환
	/// - Parameter text: 사용자가 입력한 원본 텍스트
	/// - Returns: 개인정보가 마스킹된 텍스트 (마스킹 대상이 없을 경우에는 원문 그대로 반환)
	func maskSensitiveInfo(in text: String) -> String
}

/// 마스킹 포맷 옵션
enum RRNMaskStyle {
	/// 예) 830412-1234643 → xx04xx-1xxxxxx
	case monthKeepHyphen
	/// 예) 040412-1234643 → **04**-4******
	case monthBoldStars
}

/// 개인정보 마스킹을 수행하는 기본 구현체.
/// - 이름, 주민등록번호, 전화번호, 주소(시/도 수준) 등을 감지해 안전하게 변환합니다.
/// - `PrivacyService` 프로토콜을 준수합니다.
struct DefaultPrivacyService: PrivacyService {
	init() {}

	/// 사용자가 입력한 텍스트에서 개인정보를 제거/축약한 문자열을 반환합니다.
	/// - Parameter text: 원본 입력 문자열
	/// - Returns: 마스킹된 문자열 (대상이 없으면 원문 그대로 반환)
	func maskSensitiveInfo(in text: String) -> String {
		var string = text
		string = Self.maskResidentRegistration(in: string, style: .monthKeepHyphen)
		string = Self.maskPhoneNumbers(in: string)
		string = Self.maskNames(in: string)
		
		// 주소는 "시/도만" 남김
		if let province = AddressRegionClassifier.maskedAddress(from: string, style: .provinceOnly) {
			string = province
		}
		return string
	}
}

// MARK: - 이름(인명) 마스킹
private extension DefaultPrivacyService {
	/// 인명 토큰을 “성 + 모씨” 형태로 축약합니다.
	///
	/// `NLTagger`의 `nameType` 스킴을 사용하여 한글 인명을 식별하고,
	/// 토큰의 첫 글자만 남긴 후 “모씨”를 덧붙입니다. (예: “홍길동” → “홍모씨”)
	///
	/// - Parameter text: 원문 문자열
	/// - Returns: 인명이 마스킹된 문자열
	static func maskNames(in text: String) -> String {
		var output = text
		let tagger = NLTagger(tagSchemes: [.nameType])
		tagger.string = text
		tagger.setLanguage(.korean, range: text.startIndex..<text.endIndex)
		let opts: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]

		var replacements: [(Range<String.Index>, String)] = []
		tagger.enumerateTags(in: text.startIndex..<text.endIndex,
							 unit: .word,
							 scheme: .nameType,
							 options: opts) { tag, r in
			if tag == .personalName {
				let token = String(text[r])
				let rep = token.first.map { "\($0)모씨" } ?? "모씨"
				replacements.append((r, rep))
			}
			return true
		}
		// 뒤에서 앞으로 치환 (인덱스 무효화 방지)
		for (r, rep) in replacements.sorted(by: { $0.0.lowerBound > $1.0.lowerBound }) {
			output.replaceSubrange(r, with: rep)
		}
		return output
	}
}

// MARK: - 주민등록번호: 간단 유효성 + 마스킹
private extension DefaultPrivacyService {
	static func maskResidentRegistration(in text: String, style: RRNMaskStyle) -> String {
		// YYMMDD-ABCDEFG 또는 YYMMDDABCDEFG (공백/하이픈 허용)
		// 7번째: 1~8 1,2 / 3,4 / 5,6 / 7,8
		let pattern = #"\b(\d{2})(\d{2})(\d{2})[-\s]?([1-8])(\d{6})\b"#
		return text.replacingOccurrences(of: pattern) { m in
			let yy = m[1], mm = m[2], dd = m[3], genderCodes = m[4] // g: 1~8
			guard isValidDateYYMMDD(yy: yy, mm: mm, dd: dd) else {
				return fallbackMask(mm: mm, g: genderCodes, style: style)
			}
			switch style {
			case .monthKeepHyphen: return "xx\(mm)xx-\(genderCodes)xxxxxx"
			case .monthBoldStars:  return "**\(mm)**-\(genderCodes)******"
			}
		}
	}
	
	/// `YYMMDD`의 월/일 형식이 유효한지 간단히 검사합니다.
	///
	/// - Parameters:
	///   - yy: 연도 뒤 2자리 (세기 판정은 7번째 자리로 유추하므로 여기선 미사용)
	///   - mm: 월(01~12)
	///   - dd: 일(월별 일수 내)
	/// - Returns: 형식이 합당하면 `true`
	static func isValidDateYYMMDD(yy: String, mm: String, dd: String) -> Bool {
		guard let m = Int(mm), let d = Int(dd), (1...12).contains(m) else { return false }
		let days = [31,28,31,30,31,30,31,31,30,31,30,31]
		return (1...days[m - 1]).contains(d)
	}
	/// 유효성 검사 실패 시에도 민감 노출을 방지하기 위한 안전 마스킹을 수행합니다.
	///
	/// - Parameters:
	///   - mm: 월
	///   - g: 7번째 자릿수(1~8), genderCode
	///   - style: 마스킹 스타일
	/// - Returns: 안전 마스킹 문자열
	static func fallbackMask(mm: String, g: String, style: RRNMaskStyle) -> String {
		switch style {
		case .monthKeepHyphen: return "xx\(mm)xx-\(g)xxxxxx"
		case .monthBoldStars:  return "**\(mm)**-\(g)******"
		}
	}
}

// MARK: - 전화번호: 010-5***-0***
private extension DefaultPrivacyService {
	/// 휴대전화 번호(예: 010-1234-5678)를 `010-1***-5***` 형태로 축약합니다.
	///
	/// - Parameter text: 원문 문자열
	/// - Returns: 전화번호가 마스킹된 문자열
	static func maskPhoneNumbers(in text: String) -> String {
		let pattern = #"\b(010)[-\s]?(\d{3,4})[-\s]?(\d{4})\b"#
		return text.replacingOccurrences(of: pattern) { m in
			let head = m[1], mid = m[2], tail = m[3]
			return "\(head)-\(keepFirstMaskRest(mid))-\(keepFirstMaskRest(tail))"
		}
	}
	
	/// 문자열의 **첫 글자만 남기고** 나머지는 `*`로 대체합니다.
	///
	/// - Parameter s: 원문 문자열
	/// - Returns: 첫 글자를 제외한 모든 문자를 `*`로 치환한 문자열
	static func keepFirstMaskRest(_ s: String) -> String {
		guard let first = s.first else { return s }
		return String(first) + String(repeating: "*", count: max(0, s.count - 1))
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
