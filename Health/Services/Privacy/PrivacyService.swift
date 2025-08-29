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
		replacements += findAddressReplacements(in: text)
		replacements += findRRNReplacements(in: text)
		replacements += findPhoneReplacements(in: text)
		replacements += findNameReplacements(in: text)
		
		// 충돌 방지를 위해 뒤에서부터 교체
		replacements.sort { $0.0.location > $1.0.location }
		
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
		let nsText = text as NSString
		
		// 1단계: NLTagger로 개인 이름 감지
		let tagger = NLTagger(tagSchemes: [.nameType])
		tagger.string = text
		
		let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
		
		tagger.enumerateTags(in: text.startIndex..<text.endIndex,
							 unit: .word,
							 scheme: .nameType,
							 options: options) { tag, tokenRange in
			if tag == .personalName {
				let name = String(text[tokenRange])
				if isKoreanName(name) {
					let nsRange = NSRange(tokenRange, in: text)
					let maskedName = maskKoreanName(name)
					results.append((nsRange, maskedName))
				}
			}
			return true
		}
		
		// 2단계: 정규식으로 놓친 패턴들 추가 처리
		let patterns = [
			// "이지훈이고" 패턴
			#"([가-힣]{2,4})(?=이고)"#,
			#"([가-힣]{2,4})(?=고)"#,
			// "내 이름은 김길동" 패턴
			#"(?<=내\s이름은\s)([가-힣]{2,4})"#,
			#"(?<=나는\s)([가-힣]{2,4})(?=이)"#,
			#"(?<=저는\s)([가-힣]{2,4})(?=이)"#,
			#"(?<=이름은\s)([가-힣]{2,4})"#,
			#"(?<=제\s이름은\s)([가-힣]{2,4})"#,
			
			// "김길동입니다", "김길동이에요" 패턴
			#"([가-힣]{2,4})(?=입니다|이에요|이예요|야|이야)"#,
			
			// "김길동인데" 패턴
			#"([가-힣]{2,4})(?=인데|이거든|라고)"#
		]
		
		for pattern in patterns {
			if let regex = try? NSRegularExpression(pattern: pattern) {
				let range = NSRange(text.startIndex..<text.endIndex, in: text)
				regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
					guard let match = match else { return }
					let nameRange = match.range(at: 1)
					let name = nsText.substring(with: nameRange)
					
					if isKoreanName(name) {
						// 이미 처리된 범위와 겹치는지 확인
						let alreadyProcessed = results.contains { existing in
							NSIntersectionRange(existing.0, match.range).length > 0
						}
						
						if !alreadyProcessed {
							let maskedName = maskKoreanName(name)
							results.append((match.range, maskedName))
						}
					}
				}
			}
		}
		
		return results
	}
	
	// 한국어 이름 판별
	static func isKoreanName(_ name: String) -> Bool {
		let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard trimmed.count >= 2 && trimmed.count <= 4 else { return false }
		
		return trimmed.allSatisfy { char in
			char.unicodeScalars.allSatisfy { scalar in
				(scalar.value >= 0xAC00 && scalar.value <= 0xD7AF) // 한글 완성형
			}
		}
	}
	
	// 한국어 이름 마스킹
	static func maskKoreanName(_ name: String) -> String {
		let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.count >= 2 {
			let firstChar = String(trimmed.prefix(1))
			return firstChar + "모씨"
		}
		return trimmed
	}
	
	// MARK: - 주민등록번호 마스킹 (13자리 연속 + 하이픈 패턴)
	static func findRRNReplacements(in text: String) -> [(NSRange, String)] {
		var results: [(NSRange, String)] = []
		
		let patterns = [
			// 하이픈 있는 패턴: 830412-1234567
			#"(?<!\d)(\d{2})(\d{2})(\d{2})[-]([1-8])(\d{6})(?!\d)"#,
			
			// 13자리 연속 패턴: 8304121234567
			#"(?<!\d)(\d{2})(\d{2})(\d{2})([1-8])(\d{6})(?!\d)"#
		]
		
		for pattern in patterns {
			guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
			let range = NSRange(text.startIndex..<text.endIndex, in: text)
			
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
		return AddressRegionClassifier.findAddressReplacements(in: text)
	}
}
