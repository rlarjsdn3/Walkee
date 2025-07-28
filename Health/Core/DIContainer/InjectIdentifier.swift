//
//  DIContainer+Key.swift
//  DIContainerProject
//
//  Created by 김건우 on 7/26/25.
//

import Foundation

/// 의존성을 고유하게 식별하기 위한 식별자 타입입니다.
///
/// 타입 정보와 선택적인 이름(`name`)을 기반으로 객체를 구분하며,
/// DI 컨테이너 내부에서 등록 및 조회 시 `Hashable` 키로 사용됩니다.
struct InjectIdentifier<Object> {

    /// 식별할 객체의 타입입니다.
    private(set) var type: Object.Type

    /// 동일한 타입의 객체를 구분하기 위한 선택적 이름입니다.
    private(set) var name: String? = nil
}

extension InjectIdentifier: Hashable {

    static func == (lhs: InjectIdentifier<Object>, rhs: InjectIdentifier<Object>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type))
        if let name = self.name {
            hasher.combine(name)
        }
    }
}

extension InjectIdentifier {

    /// 지정한 타입과 선택적 이름을 기반으로 식별자를 생성합니다.
    ///
    /// - Parameters:
    ///   - type: 객체의 타입입니다.
    ///   - name: 동일한 타입 내에서 객체를 구분하기 위한 선택적 이름입니다. 기본값은 `nil`입니다.
    /// - Returns: 생성된 `InjectIdentifier` 인스턴스입니다.
    static func by(type: Object.Type, name: String? = nil) -> Self {
        self.init(type: type, name: name)
    }
}
