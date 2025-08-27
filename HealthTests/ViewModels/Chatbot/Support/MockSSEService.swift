//
//  MockSSEService.swift
//  HealthTests
//
//  Created by Nat Kim on 8/27/25.
//

import Foundation
@testable import Health


final class MockSSEService: AlanSSEServiceProtocol {
	enum Mode {
		case yield([AlanStreamingResponse])
		case error(Error)
		case sequence([Mode]) // 첫 호출부터 순차적 모드 소비
	}
	private var modes: [Mode]

	init(mode: Mode) {
		if case .sequence(let arr) = mode { self.modes = arr }
		else { self.modes = [mode] }
	}

	func stream(content: String) throws -> AsyncThrowingStream<AlanStreamingResponse, any Error> {
		guard !modes.isEmpty else { return AsyncThrowingStream { $0.finish() } }
		let current = modes.removeFirst()
		switch current {
		case .yield(let events):
			return AsyncThrowingStream { cont in
				Task {
					for event in events {
						cont.yield(event)
						try? await Task.sleep(nanoseconds: 150_000)
					}
					cont.finish()
				}
			}
		case .error(let err):
			return AsyncThrowingStream { cont in cont.finish(throwing: err) }
		case .sequence(let rest):
			modes.insert(contentsOf: rest, at: 0)
			return try stream(content: content)
		}
	}
}
