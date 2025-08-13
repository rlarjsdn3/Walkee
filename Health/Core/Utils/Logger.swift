//
//  Logger.swift
//  Health
//
//  Created by Nat Kim on 8/12/25.
//

import os

/// Log 확인용
///  bundle ID 에 들어가는 것은 본인의 bundle ID로 xcconfig와 동일하게 변경하고 Log 확인 가능함.
enum Log {
	static let net = Logger(subsystem: "com.seohyun.walking", category: "NET")   // 연결, 헤더, 상태
	static let sse = Logger(subsystem: "com.seohyun.walking", category: "SSE")   // 청크, 블록, 파싱
	static let ui  = Logger(subsystem: "com.seohyun.walking", category: "UI")    // 테이블/셀/스크롤
}
