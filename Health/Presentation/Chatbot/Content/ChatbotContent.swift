//
//  ChatbotContent.swift
//  Health
//
//  Created by Nat Kim on 8/5/25.
//

import UIKit

enum MessageType {
	case user
	case ai
}

struct ChatMessage {
	let text: String
	let type: MessageType
	let timestamp: Date
	
	init(text: String, type: MessageType) {
		self.text = text
		self.type = type
		self.timestamp = Date()
	}
}
