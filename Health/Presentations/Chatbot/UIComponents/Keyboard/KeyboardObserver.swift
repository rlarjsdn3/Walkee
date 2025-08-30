//
//  KeyboardObserver.swift
//  Health
//
//  Created by Seohyun Kim on 8/11/25.
//

import UIKit
/// 키보드 이벤트를 관찰하고, 변화를 콜백으로 전달하는 헬퍼.
/// - 역할: `KeyboardEvents.willChangeFrameStream()` 을 구독해 UI 레이아웃 조정에 활용.
/// - Note: Task 기반으로 동작하므로 필요 시 `stopObserving()` 으로 반드시 취소.
@MainActor
final class KeyboardObserver {
	/// 이벤트 구독 Task
	var task: Task<Void, Never>?
	
	/// 키보드 변경 이벤트 관찰 시작
	/// - Parameter handler: 키보드 프레임 변경 시 호출되는 핸들러
	func startObserving(handler: @MainActor @escaping (KeyboardChangePayload) -> Void) {
		stopObserving()
		task = Task { @MainActor in
			for await payload in KeyboardEvents.willChangeFrameStream() {
				// 필요시 경고 억제용: await Task.yield()
				handler(payload)
			}
		}
	}
	/// 관찰 중단 및 Task 취소
	func stopObserving() {
		task?.cancel()
		task = nil
	}

	deinit {
		
	}
}
