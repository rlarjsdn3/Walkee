//
//  PromptGenService.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import Foundation

@MainActor
protocol PromptGenService {
    
    ///
    func makePrompt(
        message extraInstructions: String,
        context: PromptContext?,
        option: PromptOption
    ) async throws -> String
}
