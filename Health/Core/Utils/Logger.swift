//
//  Logger.swift
//  Health
//
//  Created by Seohyun Kim on 8/12/25.
//
import Foundation
import os

/// Log 확인용
///  bundle ID 에 들어가는 것은 본인의 bundle ID로 xcconfig와 동일하게 변경하고 Log 확인 가능함.
enum Log {
	private static let subsystem = Bundle.main.bundleIdentifier!
	// 연결, 헤더, 상태
	static let net = Logger(subsystem: subsystem, category: "NET")
	// 청크, 블록, 파싱
	static let sse = Logger(subsystem: subsystem, category: "SSE")
	// 테이블/셀/스크롤
	static let ui  = Logger(subsystem: subsystem, category: "UI")
	// 개인정보 처리
	static let privacy = Logger(subsystem: subsystem, category: "privacy")
	static let chat = Logger(subsystem: subsystem, category: "chat")
}
