//
//  AlanSSEParser.swift
//  Health
//
//  Created by Seohyun Kim on 8/19/25.
//

import Foundation

//private extension Duration {
//	var milliseconds: Double {
//		let (s, attos) = components
//		return Double(s) * 1000.0 + Double(attos) / 1e15
//	}
//}
/// SSE `data:` 페이로드(JSON 텍스트)를 AlanStreamingResponse로 디코딩.
/// 서버가 싱글쿼트를 섞는 등 비표준 JSON을 보낼 경우를 보정.
enum AlanSSEParser {
	/// 일반 디코딩 → 실패 시 싱글쿼트/키 보정 후 재시도
	/*
	 static func decodeEvent(_ json: String,
							 using decoder: JSONDecoder = JSONDecoder()) throws -> AlanStreamingResponse {
		 if let data = json.data(using: .utf8),
			let dto = try? decoder.decode(AlanStreamingResponse.self, from: data) {
			 return dto
		 }
		 let fixed = coerceSingleQuotedJSON(json)
		 guard let fixedData = fixed.data(using: .utf8) else {
			 throw NSError(domain: "SSE",
						   code: -10,
						   userInfo: [NSLocalizedDescriptionKey:"invalid encoding"])
		 }
		 return try decoder.decode(AlanStreamingResponse.self, from: fixedData)
	 }
	 */
	// 파싱 속도 체크를 위한 임시 메서드 코드 
	static func decodeEvent(_ json: String,
							using decoder: JSONDecoder = JSONDecoder()) throws -> AlanStreamingResponse {
		let t0 = ContinuousClock.now
		defer {
			let ms = t0.duration(to: .now).milliseconds
			NotificationCenter.default.post(name: .sseParseDidRecord, object: nil, userInfo: ["ms": ms])
		}
		
		if let data = json.data(using: .utf8),
		   let dto = try? decoder.decode(AlanStreamingResponse.self, from: data) {
			return dto
		}
		let fixed = coerceSingleQuotedJSON(json)
		let fixedData = fixed.data(using: .utf8)!
		return try decoder.decode(AlanStreamingResponse.self, from: fixedData)
	}
	
	/// '{'type':'continue', 'data':{...}}' → {"type":"continue","data":{...}}
	static func coerceSingleQuotedJSON(_ raw: String) -> String {
		var fixed = raw.replacingOccurrences(
			of: #"'([A-Za-z0-9_]+)'\s*:"#,
			with: #""$1":"#,
			options: .regularExpression
		)
		fixed = fixed.replacingOccurrences(
			of: #":\s*'([^']*)'"#,
			with: #": "$1""#,
			options: .regularExpression
		)
		return fixed
	}
	
	// 필요 시 살려두는 옵션(현재 미사용): 싱글쿼트 기반 pseudo-JSON fallback 파싱
	/// 서버가 싱글쿼트로 보내는 payload에서 type/speak/content만 안전 추출
	private func fallbackParsePseudoJSON(_ s: String) -> AlanStreamingResponse? {
		func match(_ pattern: String) -> String? {
			let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
			guard let m = regex.firstMatch(in: s, options: [], range: NSRange(location: 0, length: (s as NSString).length)),
				  m.numberOfRanges >= 2 else { return nil }
			return (s as NSString).substring(with: m.range(at: 1))
		}
		
		guard let typeStr = match(#"type':\s*'([^']+)'"#) else { return nil }
		
		// content와 speak 둘 다 시도
		let rawContent = match(#"content':\s*'(.*)'\s*}\s*}"#)
		let rawSpeak   = match(#"speak':\s*'(.*)'\s*}\s*}"#)
		
		// 치환: \n -> 실제 개행
		func normalize(_ t: String?) -> String? {
			t?.replacingOccurrences(of: #"\\n"#, with: "\n")
		}
		
		let type = AlanStreamingResponse.StreamingType(rawValue: typeStr) ?? .continue
		let dto  = AlanStreamingResponse(
			type: type,
			data: .init(content: normalize(rawContent) ?? normalize(rawSpeak),
						speak: normalize(rawSpeak))
		)
		//Log.sse.info("fallback parsed type=\(type.rawValue, privacy: .public) len=\((dto.data.content ?? "").count, privacy: .public)")
		return dto
	}
}
