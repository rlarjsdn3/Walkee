//
//  ChatbotWidthProfile.swift
//  Health
//
//  Created by Nat Kim on 8/10/25.
//

import UIKit

/// 챗봇 메시지 UI의 최대 너비 정책
enum ChatbotWidthProfile: Equatable {
	/// 사용자 말풍선(UIView 기반 버블)
	case userBubble
	/// AI 응답 텍스트뷰(고정 width 제약)
	case aiResponseText
	/// 로딩 인디케이터 + 텍스트(스택)
	case loadingText
	/// 필요 시 직접 지정 (비율 또는 고정 최대값)
	case custom(multiplier: CGFloat = 0.75, fixedMax: CGFloat? = nil)
}
