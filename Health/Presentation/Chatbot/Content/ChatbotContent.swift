//
//  ChatbotContent.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit

enum MessageType: Equatable {
	/// 사용자가 요청하는 프롬프트 메시지
	case user
	/// LLM ai가 응답하는 메시지
	case ai
	/// 실시간으로 변하는 로딩 메시지
	case loading
	/// 간격 셀 (높이 값 포함)
	case spacer(CGFloat)
	/// 대화 종료 버튼 셀
	case endChat
	
	// Equatable 프로토콜을 위한 == 연산자 오버로드
	// 연관 값을 비교하지 않고 케이스만 비교하도록 구현
	static func == (lhs: MessageType, rhs: MessageType) -> Bool {
		switch (lhs, rhs) {
		case (.user, .user), (.ai, .ai), (.spacer, .spacer), (.endChat, .endChat), (.loading, .loading):
			return true
		default:
			return false
		}
	}
}

struct ChatMessage {
	var text: String
	let type: MessageType
	let timestamp: Date
	
	init(text: String, type: MessageType) {
		self.text = text
		self.type = type
		self.timestamp = Date()
	}
}
