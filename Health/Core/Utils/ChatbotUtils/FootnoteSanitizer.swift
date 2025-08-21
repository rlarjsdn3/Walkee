//
//  FootnoteSanitizer.swift
//  Health
//
//  Created by Seohyun Kim on 8/20/25.
//
import Foundation

enum FootnoteSanitizer {
	// MARK: 각주 [^ number ^] 는 제거하는 메서드
	static func sanitize(_ text: String, inFootnote: inout Bool, pendingOpenBracket: inout Bool) -> String {
		guard !text.isEmpty else { return text }
		var output = ""
		var i = text.startIndex
		// 이전 조각이 '[' 로 끝났고, 이번 조각이 '^' 로 시작하면 각주 진입
		if pendingOpenBracket {
			if text.first == "^" {
				inFootnote = true
				pendingOpenBracket = false
				i = text.index(after: i)
			} else {
				// 각주 아님: 보류했던 '[' 출력
				output.append("[")
				pendingOpenBracket = false
			}
		}
		
		while i < text.endIndex {
			let ch = text[i]
			
			if inFootnote {
				// 각주 모드: ']' 나올 때까지 모두 버림
				if ch == "]" { inFootnote = false }
				i = text.index(after: i)
				continue
			}
			
			if ch == "[" {
				let next = text.index(after: i)
				if next < text.endIndex {
					if text[next] == "^" {
						// '[^' 발견 → 각주 모드 진입, 둘 다 소비
						inFootnote = true
						i = text.index(after: next)
						continue
					} else {
						output.append("[")
						i = next
						continue
					}
				} else {
					// 조각 끝이 '[' 로 끝남 → 다음 조각에서 판단
					pendingOpenBracket = true
					break
				}
			}
			
			output.append(ch)
			i = text.index(after: i)
		}
		
		return output
	}
	
	static func stripAllFootnotes(from text: String) -> String {
		let pattern = #"\[\^[^\]]*\]"#
		let regex = try? NSRegularExpression(pattern: pattern)
		let range = NSRange(location: 0, length: (text as NSString).length)
		return regex?.stringByReplacingMatches(in: text, range: range, withTemplate: "") ?? text
	}
}
