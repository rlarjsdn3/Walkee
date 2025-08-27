//
//  AlanStreamingResponse+Factory.swift
//  HealthTests
//
//  Created by Nat Kim on 8/27/25.
//

import Foundation
@testable import Health

extension AlanStreamingResponse {
	static func action(_ speak: String) -> Self {
		.init(type: .action, data: .init(content: nil, speak: speak))
	}
	static func `continue`(_ content: String) -> Self {
		.init(type: .continue, data: .init(content: content, speak: nil))
	}
	static func complete(_ content: String) -> Self {
		.init(type: .complete, data: .init(content: content, speak: nil))
	}
}
