//
//  Prompt+String.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import Foundation

typealias PromptString = String.Prompt
extension String {

    struct Prompt {

        /// 지정된 메시지를 기반으로 프롬프트 문자열을 생성합니다.
        ///
        /// 현재는 구현이 비어 있으나, 향후 사용자 입력을 위한 안내 메시지 포맷 등을 반환하는 용도로 확장될 수 있습니다.
        ///
        /// - Parameter message: 사용자에게 전달할 프롬프트 메시지입니다.
        /// - Returns: 형식화된 프롬프트 문자열입니다. (현재는 빈 문자열 반환)
        static func prompt(_ message: String) -> String {
            ""
        }
    }
}
