//
//  PromptTemplateRenderer.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import Foundation

@MainActor
protocol PromptTemplateRenderer {
    
    ///
    func render(
        with context: PromptContext,
        option: PromptOption
    ) -> String
}


