//
//  MockPromptBuilderService.swift
//  HealthTests
//
//  Created by Seohyun Kim on 8/27/25.
//

import Foundation
@testable import Health

final class MockPromptBuilderService: PromptBuilderService {
	func makePrompt(
		message extraInstructions: String?,
		context: Health.PromptContext?,
		option: Health.PromptOption
	) async throws -> String {
		var parts: [String] = ["[PROMPT]"]
		
		if let m = extraInstructions, !m.isEmpty {
			parts.append("message=\(m)")
		}
		if let c = context {
			// 구체 타입 모를 때는 안전하게 String(describing:) 사용
			parts.append("context=\(String(describing: c))")
		}
		parts.append("option=\(String(describing: option))")
		
		return parts.joined(separator: " ")
	}
}
