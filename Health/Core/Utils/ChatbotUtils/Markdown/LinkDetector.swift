//
//  LinkDetector.swift
//  Health
//
//  Created by Seohyun Kim on 8/21/25.
//
import UIKit

enum LinkDetector {
	/// 기존 어트리뷰트 유지하면서 URL에 `.link` 속성 부여
	static func highlightLinks(in source: NSAttributedString) -> NSAttributedString {
		let mutable = NSMutableAttributedString(attributedString: source)
		let full = NSRange(location: 0, length: mutable.length)
		let plain = mutable.string

		if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
			detector.enumerateMatches(in: plain, options: [], range: full) { match, _, _ in
				guard let match, let url = match.url else { return }
				// 이미 링크면 덮어쓰지 않음
				let existing = mutable.attribute(.link, at: match.range.location, effectiveRange: nil)
				if existing == nil {
					mutable.addAttribute(.link, value: url, range: match.range)
				}
			}
		}
		return mutable
	}
}
