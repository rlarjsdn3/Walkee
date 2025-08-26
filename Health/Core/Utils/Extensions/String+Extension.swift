//
//  String+Extension.swift
//  Health
//
//  Created by 김건우 on 8/26/25.
//

import Foundation

extension String {

    /// 문자열에 포함된 마크다운 문법을 제거한 새로운 문자열을 반환합니다.
    ///
    /// - Returns: 마크다운 문법이 제거된 순수 텍스트 문자열
    func removingMarkdown() -> String {
        var result = self

        result = result.replacingOccurrences(
            of: "\\*\\*(.*?)\\*\\*",
            with: "$1",
            options: .regularExpression,
        )

        result = result.replacingOccurrences(
            of: "\\*(.*?)\\*",
            with: "$1",
            options: .regularExpression
        )

        result = result.replacingOccurrences(
            of: "`(.*?)`",
            with: "$1",
            options: .regularExpression
        )

        result = result.replacingOccurrences(
            of: "\\[(.*?)\\]\\((.*?)\\)",
            with: "",
            options: .regularExpression
        )

        return result
    }
}
