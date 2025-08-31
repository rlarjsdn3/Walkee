//
//  ChatbotMessageContent.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit
/// 메시지의 타입 (사용자/AI/로딩)
enum MessageType: Equatable {
	/// 사용자가 요청하는 프롬프트 메시지
	case user
	/// LLM ai가 응답하는 메시지
	case ai
	/// 실시간으로 변하는 로딩 메시지
	case loading
	// Equatable 프로토콜을 위한 == 연산자 오버로드
	// 연관 값을 비교하지 않고 케이스만 비교하도록 구현
	static func == (lhs: MessageType, rhs: MessageType) -> Bool {
		switch (lhs, rhs) {
		case (.user, .user), (.ai, .ai), (.loading, .loading):
			return true
		default:
			return false
		}
	}
}
/// 채팅 메시지 단위 모델
/// - text: 메시지 내용
/// - type: 메시지 타입
struct ChatMessage {
	var text: String
	let type: MessageType

	init(text: String, type: MessageType) {
		self.text = text
		self.type = type
	}
}

extension MessageType: CustomStringConvertible {
	var description: String {
		switch self {
		case .user: return "user"
		case .ai: return "ai"
		case .loading: return "loading"
		}
	}
}
