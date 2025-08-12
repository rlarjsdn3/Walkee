//
//  ChatbotContent.swift
//  Health
//
//  Created by Seohyun Kim on 8/5/25.
//

import UIKit

enum MessageType {
	/// 사용자가 요청하는 프롬프트 메시지
	case user
	/// LLM ai가 응답하는 메시지
	case ai
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
