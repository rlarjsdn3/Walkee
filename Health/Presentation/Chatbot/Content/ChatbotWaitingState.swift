//
//  ChatbotWaitingState.swift
//  Health
//
//  Created by Nat Kim on 8/28/25.
//

import Foundation

enum WaitingCellState {
	// 로딩 중: 인디케이터 ON
	case waiting(String)
	// 오류: 인디케이터 OFF
	case error(String)
}
