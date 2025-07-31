//
//  NSObject+ID.swift
//  Health
//
//  Created by 김건우 on 7/31/25.
//

import Foundation

extension NSObject {

    /// 현재 객체의 클래스 이름을 문자열로 반환합니다.
    ///
    /// 네임스페이스(모듈 이름)를 제외한 클래스 이름만 반환되며,
    /// 주로 식별자나 리유즈 아이디 등으로 활용할 수 있습니다.
    var id: String {
        NSStringFromClass(Self.self)
            .components(separatedBy: ".")
            .last!
    }
}
