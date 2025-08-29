//
//  KeyboardObserver.swift
//  Health
//
//  Created by Seohyun Kim on 8/11/25.
//

import UIKit

@MainActor
final class KeyboardObserver {
	var task: Task<Void, Never>?

	init() {}

	func startObserving(handler: @MainActor @escaping (KeyboardChangePayload) -> Void) {
		stopObserving()
		task = Task { @MainActor in
			for await payload in KeyboardEvents.willChangeFrameStream() {
				// MARK: 필요시 경고 억제용: await Task.yield()
				handler(payload)
			}
		}
	}

	func stopObserving() {
		task?.cancel()
		task = nil
	}

	deinit {
		
	}
}
