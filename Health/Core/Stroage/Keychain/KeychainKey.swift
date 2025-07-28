//
//  KeychainWrapperKeys.swift
//  KeychainWrapperProject
//
//  Created by 김건우 on 7/27/25.
//

import Foundation

/// `KeychainKey`는 키체인에 저장되는 항목의 키 정보를 표현하기 위한 구조체입니다.
///
/// 제네릭 타입 `Value`를 사용하여 키에 저장될 값의 타입을 명확히 지정할 수 있으며,
/// 문자열 리터럴로도 쉽게 초기화할 수 있도록 `ExpressibleByStringLiteral` 프로토콜을 채택하고 있습니다.
struct KeychainKey<Value>: ExpressibleByStringLiteral {

    /// 키체인에 저장될 항목의 키 이름입니다.
    var name: String

    /// 주어진 이름으로 `KeychainKey`를 초기화합니다.
    ///
    /// - Parameter name: 키체인 항목을 식별하기 위한 고유한 문자열 키입니다.
    init(name: String) {
        self.name = name
    }

    /// 문자열 리터럴을 사용하여 `KeychainKey`를 초기화합니다.
    ///
    /// - Parameter value: 문자열 리터럴 형태의 키 이름입니다.
    init(stringLiteral name: StringLiteralType) {
        self.name = name
    }
}
