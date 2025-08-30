//
//  AddressRegionClassifier.swift
//  Health
//
//  Created by Seohyun Kim on 8/16/25.
//

import Foundation

// MARK: - 공개 옵션

enum AddressMaskDepth {
	// 시/도만
	case province
	// 시/도 + 시/군/구
	case city
	// 기본: 시/도 + 시/군/구 + 읍/면/동/리/동n가까지만 (상세 차단)
	case district
}

struct AddressMaskOptions {
	var depth: AddressMaskDepth = .district
	init(depth: AddressMaskDepth = .district) { self.depth = depth }
}

// 마스킹 스타일 (최종 텍스트 생성 규칙)
enum AddressMaskStyle {
	// 시/도만 반환
	case provinceOnly
	// 시/도 + 시/군/구 (필요시)
	case provinceWithDistrict
	// 기본: 시/도 표준화 + addressRange 내 토큰(구/군/동 등) 유지
	case provinceWithCappedTail
}

struct AddressRegionClassifier {
	
	// MARK: - 시/도 별칭 (표준화)
	private static let provinceAliases: [String: String] = [
		"서울":"서울특별시","서울시":"서울특별시",
		"부산":"부산광역시","부산시":"부산광역시",
		"대구":"대구광역시","대구시":"대구광역시",
		"인천":"인천광역시","인천시":"인천광역시",
		"광주":"광주광역시","광주시":"광주광역시",
		"대전":"대전광역시","대전시":"대전광역시",
		"울산":"울산광역시","울산시":"울산광역시",
		"세종":"세종특별자치시","세종시":"세종특별자치시",
		"경기":"경기도",
		"강원":"강원특별자치도","강원도":"강원특별자치도",
		"충북":"충청북도","충남":"충청남도",
		"전북":"전북특별자치도","전남":"전라남도",
		"경북":"경상북도","경남":"경상남도",
		"제주":"제주특별자치도","제주도":"제주특별자치도"
	]
	
	// POI 접미사(시/도 탐지에서 “바로 뒤에 붙으면” 제외)
	private static let poiSuffixes = ["역","공원","병원","학교","시장","터미널","정류장","도서관","체육관"]
	
	// MARK: - 결과 모델
	struct AddressDetectionResult {
		let originalText: String
		let standardProvince: String
		let city: String?
		// 시/도부터 (정책에 따라) 동/리/n가까지 포함한 범위
		let range: Range<String.Index>
	}
	
	// MARK: - 진입점
	static func findAddressReplacements(
		in text: String,
		options: AddressMaskOptions = .init(),
		style: AddressMaskStyle = .provinceWithCappedTail
	) -> [(NSRange, String)] {
		
		guard let result = detectDetailedAddress(in: text, options: options) else {
			print("[AddressClassifier] 주소를 찾을 수 없음")
			return []
		}
		
		let replacement: String = makeMaskedAddress(from: result, in: text, style: style)
		let nsRange = NSRange(result.range, in: text)
		
		print("[AddressClassifier] 최종 마스킹 결과: '\(replacement)'")
		return [(nsRange, replacement)]
	}
	
	// MARK: - 상세 주소 탐지
	private static func detectDetailedAddress(
		in text: String,
		options: AddressMaskOptions
	) -> AddressDetectionResult? {
		
		let db = DistrictDB.shared
		
		// 1) 시/도 탐지
		var provinceStd: String?
		var provinceRange: Range<String.Index>?
		var provinceOriginal: String?
		
		for alias in provinceAliases.keys.sorted(by: { $0.count > $1.count }) {
			if let r = text.range(of: alias), !isImmediatelyFollowedByPOI(text, after: r) {
				provinceStd = provinceAliases[alias]
				provinceRange = r
				provinceOriginal = alias
				break
			}
		}
		
		if provinceStd == nil {
			for key in db.nameToProvince.keys.sorted(by: { $0.count > $1.count }) {
				if let r = text.range(of: key), !isImmediatelyFollowedByPOI(text, after: r) {
					provinceStd = db.nameToProvince[key]
					provinceRange = r
					provinceOriginal = key
					break
				}
			}
		}
		
		if provinceStd == nil {
			for prov in db.provinceNames.sorted(by: { $0.count > $1.count }) {
				if let r = text.range(of: prov), !isImmediatelyFollowedByPOI(text, after: r) {
					provinceStd = prov
					provinceRange = r
					provinceOriginal = prov
					break
				}
			}
		}
		
		guard let std = provinceStd, let pRange = provinceRange, let pOrig = provinceOriginal else { return nil }
		
		// 2) 구/군 탐색
		var foundCity: String?
		if let cities = findProvinceData(province: std, in: db) {
			for c in cities.sorted(by: { $0.count > $1.count }) {
				if text.contains(c) { foundCity = c; break }
			}
		}
		
		// 3) 범위 결정
		let range = determineAddressRange(text: text, provinceRange: pRange, options: options)
		print("[AddressClassifier] 주소 범위: '\(String(text[range]))'")
		
		return .init(
			originalText: pOrig,   // ✅ originalProvinceText → originalText
			standardProvince: std,
			city: foundCity,
			range: range
		)
	}
	
	// 시/도 뒤에 POI 붙은 경우 제외
	private static func isImmediatelyFollowedByPOI(_ text: String, after r: Range<String.Index>) -> Bool {
		guard r.upperBound < text.endIndex else { return false }
		let nextChar = text[r.upperBound]
		if nextChar.isWhitespace { return false }
		var j = r.upperBound
		while j < text.endIndex, !text[j].isWhitespace { j = text.index(after: j) }
		let token = String(text[r.upperBound..<j])
		return poiSuffixes.contains(where: { token.hasSuffix($0) })
	}
	
	// MARK: - 범위 산정
	private static func determineAddressRange(
		text: String,
		provinceRange: Range<String.Index>,
		options: AddressMaskOptions
	) -> Range<String.Index> {

		// ── 토큰 규칙 ───────────────────────────
		let stopTokens: Set<String>  = ["사는","거주","살고","살아요","사는데","인데","입니다","이에요"]
		let postMods: Set<String>    = ["근처","쪽","주변","인근","부근","가까운","에서","으로","로","가서","에"]
		let poiSuffixes              = ["역","공원","병원","학교","시장","터미널","정류장","도서관","체육관"]

		let adminSuffixes  = ["시","군","구","읍","면","동","리"]
		let detailSuffixes = ["로","길","번지","호","단지","빌딩","타워","테라스","오피스텔","상가","센터","층"]

		let detailRegexes: [NSRegularExpression] = [
			try! .init(pattern: #"[가-힣]+동\d+가"#),        // 성수동1가
			try! .init(pattern: #"\d+(-\d+)?번지"#),        // 12-3번지
			try! .init(pattern: #"\d+(동|호|층)"#),         // 104동, 2601호, 26층
			try! .init(pattern: #"[A-Za-z가-힣0-9]+(로|길)"#) // 만현로, OO길
		]

		func isDetailWord(_ w: String) -> Bool {
			if detailSuffixes.contains(where: { w.hasSuffix($0) }) { return true }
			let ns = w as NSString
			return detailRegexes.contains { $0.firstMatch(in: w, range: NSRange(location: 0, length: ns.length)) != nil }
		}
		func isPunctOnly(_ w: String) -> Bool {
			w.unicodeScalars.allSatisfy { CharacterSet.punctuationCharacters.contains($0) }
		}

		let provinceStd = detectProvince(in: text)
		let districtCandidates: [String] = DistrictDB.shared.nameToProvince
			.filter { $0.value == provinceStd }
			.map { $0.key }
			.sorted { $0.count > $1.count }

		func isDistrictName(_ w: String) -> Bool {
			districtCandidates.contains(where: { $0 == w }) ||
			adminSuffixes.contains(where: { w.hasSuffix($0) })
		}
		func shouldStopAfterDistrictToken(_ token: String, options: AddressMaskOptions) -> Bool {
			guard options.depth == .district else { return false }
			if token.hasSuffix("읍") || token.hasSuffix("면") || token.hasSuffix("동") || token.hasSuffix("리") { return true }
			if token.range(of: #"[가-힣]+동\d+가$"#, options: .regularExpression) != nil { return true }
			return false
		}
		func looksLikeBuildingName(_ w: String) -> Bool {
			let buildingHints = ["아파트","오피스텔","빌라","주상복합","스퀘어","시티","타워","팰리스","캐슬","파크",
								 "프라자","센트럴","리버뷰","레이크","테라스","스테이트","포레","트윈",
								 "더샵","푸르지오","자이","래미안","힐스테이트","아이파크","트리마제","카운티"]
			if buildingHints.contains(where: { w.contains($0) }) { return true }
			if w.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil { return true }
			if w.range(of: #"[0-9][A-Za-z]|[A-Za-z][0-9]"#, options: .regularExpression) != nil { return true }
			return false
		}

		typealias Token = (value: String, range: Range<String.Index>)
		func tokenize(_ s: Substring) -> [Token] {
			var out: [Token] = []; var i = s.startIndex
			while i < s.endIndex {
				while i < s.endIndex, s[i].isWhitespace { i = s.index(after: i) }
				guard i < s.endIndex else { break }
				var j = i
				while j < s.endIndex, !s[j].isWhitespace { j = s.index(after: j) }
				let r = i..<j; out.append((String(s[r]), r)); i = j
			}
			return out
		}

		// 1) ‘경기+도’, ‘서울+시’ 한 글자 접미 스킵
		var afterStart = provinceRange.upperBound
		if afterStart < text.endIndex {
			let ch = text[afterStart]
			if ch == "도" || ch == "시" { afterStart = text.index(after: afterStart) }
		}

		let after  = text[afterStart...]
		let tokens = tokenize(after)

		// 2) 스캔: 행정동까지 포함, 그 뒤 꼬리 확장
		var lastEnd = afterStart
		var consumed = false
		var stopIndex: Int? = nil

		// 2-1) 행정동 STOP 지점 찾기
		for (idx, (w, r)) in tokens.enumerated() {
			if isPunctOnly(w) { continue }
			if stopTokens.contains(w) || postMods.contains(w) || poiSuffixes.contains(where: { w.hasSuffix($0) }) {
				stopIndex = idx; break
			}
			if isDistrictName(w) || isDetailWord(w) {
				lastEnd = r.upperBound; consumed = true
				if shouldStopAfterDistrictToken(w, options: options) { stopIndex = idx + 1; break }
				continue
			}
			if w.allSatisfy({ $0.isNumber }) {
				if options.depth == .district { stopIndex = idx; break }
				break
			}
			if options.depth == .district, looksLikeBuildingName(w) {
				stopIndex = idx; break
			}
			break
		}

		// 2-2) 꼬리(redaction tail) 확장
		if options.depth == .district {
			var redactionEnd = lastEnd
			let tailRange = (stopIndex ?? tokens.count)..<tokens.count
			for k in tailRange {
				let (w, r) = tokens[k]
				if isPunctOnly(w) { redactionEnd = r.upperBound; continue }
				if postMods.contains(w) || stopTokens.contains(w) || poiSuffixes.contains(where: { w.hasSuffix($0) }) {
					break
				}
				if looksLikeBuildingName(w) || isDetailWord(w) || w.allSatisfy({ $0.isNumber }) {
					redactionEnd = r.upperBound
					continue
				}
				break
			}
			lastEnd = redactionEnd
		}

		return consumed ? (provinceRange.lowerBound..<lastEnd) : provinceRange
	}

	// MARK: - 건물명 휴리스틱
	private static func looksLikeBuildingName(_ w: String) -> Bool {
		// 브랜드를 다 열거하지 않고, 범용 접미/내포 + 영문/영숫 혼합으로 판별
		let buildingKeywords = [
			"아파트","오피스텔","빌라","주상복합","스퀘어","시티","타워","팰리스","캐슬","파크",
			"프라자","센트럴","리버뷰","레이크","테라스","힐스","포레","트윈","스테이트",
			// 흔한 브랜드 몇 개만 보너스 신호
			"더샵","푸르지오","자이","래미안","힐스테이트","아이파크","트리마제", "풍림", "금호"
		]
		if buildingKeywords.contains(where: { w.contains($0) }) { return true }
		if w.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil { return true }           // 영문 포함
		if w.range(of: #"[0-9][A-Za-z]|[A-Za-z][0-9]"#, options: .regularExpression) != nil { return true } // 영숫 혼합
		return false
	}
	
	
	// MARK: - 최종 치환문 생성
	private static func makeMaskedAddress(
		from result: AddressDetectionResult,
		in text: String,
		style: AddressMaskStyle
	) -> String {
		let addr = String(text[result.range])

		// 토큰 판별 유틸 (기존과 동일/간소)
		let adminSuffixes  = ["시","군","구","읍","면","동","리"]
		let detailSuffixes = ["로","길","번지","호","단지","빌딩","타워","테라스","오피스텔","상가","센터","층"]
		let buildingHints  = ["아파트","오피스텔","빌라","주상복합","스퀘어","시티","타워","팰리스","캐슬","파크",
							  "프라자","센트럴","리버뷰","레이크","테라스","힐스","포레","트윈","스테이트",
							  "더샵","푸르지오","자이","래미안","힐스테이트","아이파크","트리마제"]

		func isDetailWord(_ w: String) -> Bool {
			if detailSuffixes.contains(where: { w.hasSuffix($0) }) { return true }
			if w.range(of: #"^\d+(-\d+)?번지$"#, options: .regularExpression) != nil { return true }
			if w.range(of: #"^\d+(동|호|층)$"#, options: .regularExpression) != nil { return true }
			if w.range(of: #"[가-힣]+동\d+가$"#, options: .regularExpression) != nil { return true }
			return false
		}
		func looksLikeBuildingName(_ w: String) -> Bool {
			if buildingHints.contains(where: { w.contains($0) }) { return true }
			if w.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil { return true }
			return false
		}
		func tokenize(_ s: String) -> [String] {
			s.split(whereSeparator: { $0.isWhitespace }).map(String.init)
		}

		// 1) 선두 시/도 정규화 (중복 방지)
		let normalizedHead: String
		let restAfterProvince: [String]
		if addr.hasPrefix(result.standardProvince) {
			// 이미 표준형 → 그대로 head로 쓰되, 토큰 재평가 통해 '동'에서 STOP
			normalizedHead = result.standardProvince
			restAfterProvince = tokenize(String(addr.dropFirst(result.standardProvince.count)))
		} else if addr.hasPrefix(result.originalText) {
			// 별칭형 → standardProvince로 교체
			normalizedHead = result.standardProvince
			restAfterProvince = tokenize(String(addr.dropFirst(result.originalText.count)))
		} else {
			// 보호: 못 알아보면 시/도만
			return result.standardProvince
		}

		// 2) 행정동까지만 포함 (그 뒤 상세/숫자/건물 나오면 STOP)
		var kept: [String] = []
		var seenAdministrativeDistrict = false
		for w in restAfterProvince {
			let isAdministrative = adminSuffixes.contains(where: { w.hasSuffix($0) }) ||
								   w.range(of: #"[가-힣]+동\d+가$"#, options: .regularExpression) != nil

			if isAdministrative {
				kept.append(w)
				// ‘…동/…리/…동n가’를 만나면 STOP 플래그 on
				if w.hasSuffix("동") || w.hasSuffix("리") ||
				   w.range(of: #"[가-힣]+동\d+가$"#, options: .regularExpression) != nil {
					seenAdministrativeDistrict = true
				}
				continue
			}

			if seenAdministrativeDistrict {
				// 상세 주소 제거 (1288, 아파트, 건물명, 120동 등)
				if looksLikeBuildingName(w) || isDetailWord(w) || w.allSatisfy({ $0.isNumber }) {
					break
				}
			}

			// 시/군/구 레벨의 일반 토큰은 포함 (예: ‘부천시’, ‘원미구’)
			kept.append(w)
		}

		let masked = ([normalizedHead] + kept).joined(separator: " ")

		switch style {
		case .provinceOnly:
			return result.standardProvince
		case .provinceWithDistrict:
			if let city = result.city { return "\(result.standardProvince) \(city)" }
			return result.standardProvince
		case .provinceWithCappedTail:
			return masked
		}
	}
	// MARK: - 보조 유틸
	private static func findProvinceData(province: String, in db: DistrictIndex) -> [String]? {
		let cities = db.nameToProvince.compactMap { (city, prov) in prov == province && city != province ? city : nil }
		return cities.isEmpty ? nil : cities
	}
	
	static func detectProvince(in text: String) -> String? {
		let db = DistrictDB.shared
		for alias in provinceAliases.keys.sorted(by: { $0.count > $1.count }) {
			if let r = text.range(of: alias), !isImmediatelyFollowedByPOI(text, after: r) { return provinceAliases[alias] }
		}
		for key in db.nameToProvince.keys.sorted(by: { $0.count > $1.count }) {
			if let r = text.range(of: key), !isImmediatelyFollowedByPOI(text, after: r) { return db.nameToProvince[key] }
		}
		for prov in db.provinceNames.sorted(by: { $0.count > $1.count }) {
			if let r = text.range(of: prov), !isImmediatelyFollowedByPOI(text, after: r) { return prov }
		}
		return nil
	}
}
