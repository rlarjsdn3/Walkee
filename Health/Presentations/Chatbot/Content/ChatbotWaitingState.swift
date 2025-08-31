//
//  ChatbotWaitingState.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import Foundation
/// 대기 셀 상태
/// - waiting: 로딩 중(인디케이터 표시)
/// - error: 오류 발생(인디케이터 중단, 오류 문구 표시)
enum WaitingCellState {
	case waiting(String)
	case error(String)
}
