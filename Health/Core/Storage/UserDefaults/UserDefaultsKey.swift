//
//  UserDefaultsWrapper+Key.swift
//  UserDefaultsWrapperProject
//
//  Created by 김건우 on 7/25/25.
//

import Foundation

/// `UserDefaultsKey`는 `UserDefaults`에 저장되는 값의 키와 기본값을 함께 정의하기 위한 구조체입니다.
/// 이 구조체는 제네릭 타입 `Value`를 사용하여 다양한 타입의 값을 지원합니다.
struct UserDefaultsKey<Value> {
    
    /// `UserDefaults`에 저장될 항목의 고유한 키 이름입니다.
    let name: String
    
    /// 키에 해당하는 값이 존재하지 않을 경우 사용할 기본값입니다.
    let defaultValue: Value

    /// 새로운 `UserDefaultsKey` 인스턴스를 생성합니다.
    ///
    /// - Parameters:
    ///   - name: `UserDefaults`에 저장할 항목의 키 이름입니다.
    ///   - defaultValue: 값이 존재하지 않을 경우 사용할 기본값입니다.
    init(_ name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}
