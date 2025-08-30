//
//  UserDefaultsWrapper.swift
//  UserDefaultsWrapperProject
//
//  Created by 김건우 on 7/25/25.
//

import Foundation

/// `UserDefaultsWrapper`는 사용자 기본 설정(UserDefaults)에 안전하고 편리하게 접근할 수 있도록 도와주는 래퍼 클래스입니다.
///
/// `@dynamicMemberLookup`을 사용하여 키에 대한 접근을 간결하게 처리할 수 있으며,
/// 개발 및 배포 환경에 따라 다른 suiteName을 사용하여 설정을 구분합니다.
@dynamicMemberLookup
final class UserDefaultsWrapper: @unchecked Sendable {
    
    /// `UserDefaultsWrapper`의 공유 인스턴스입니다.
    /// 싱글톤 패턴을 사용하여 앱 전반에서 공통된 설정을 사용할 수 있도록 합니다.
    static let shared = UserDefaultsWrapper()
    
    /// 내부적으로 사용하는 `UserDefaults` 인스턴스입니다.
    private let userDefaults: UserDefaults!
    
    private init() {
#if DEBUG
        userDefaults = UserDefaults(suiteName: "com.allen.debug")
#else
        userDefaults = UserDefaults(suiteName: "com.allen.release")
#endif
    }
    
    /// 지정한 suiteName을 사용하여 새로운 `UserDefaultsWrapper` 인스턴스를 생성합니다.
    ///
    /// - Parameter suitName: `UserDefaults`를 초기화할 때 사용할 suite 이름입니다.
    init(suitName: String) {
        userDefaults = UserDefaults(suiteName: suitName)
    }
    
    /// 외부에서 주입한 `UserDefaults` 인스턴스를 사용하여 초기화합니다.
    ///
    /// - Parameter userDefaults: 커스텀 설정이나 테스트 등을 위해 주입할 `UserDefaults` 인스턴스입니다.
    init(userDefaults: UserDefaults?) {
        self.userDefaults = userDefaults
    }
    
    /// 주어진 키에 해당하는 값을 `UserDefaults`에 저장합니다.
    ///
    /// - Parameters:
    ///   - keyPath: `UserDefaultsKeys`에서 정의된 키에 대한 KeyPath입니다.
    ///   - value: 저장할 값입니다. `nil`일 경우 해당 키의 항목이 제거됩니다.
    func set<Value>(
        forKey keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Value>>,
        value: Value?
    ) {
        let key = UserDefaultsKeys()[keyPath: keyPath]
        userDefaults.set(value, forKey: key.name)
    }
    
    // MARK: - Get
    
    /// 지정한 키에 해당하는 값을 `UserDefaults`에서 가져옵니다.
    ///
    /// 값이 존재하지 않는 경우 `UserDefaultsKey`에 정의된 기본값을 반환합니다.
    ///
    /// - Parameter keyPath: `UserDefaultsKeys`에서 정의된 키에 대한 KeyPath입니다.
    /// - Returns: 저장된 값 또는 기본값을 반환합니다.
    func get<Value>(
        forKey keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Value>>
    ) -> Value {
        let key = UserDefaultsKeys()[keyPath: keyPath]
        return (userDefaults.object(forKey: key.name) as? Value) ?? key.defaultValue
    }
    
    // MARK: - Remove
    
    /// 지정한 키에 해당하는 값을 `UserDefaults`에서 삭제합니다.
    ///
    /// - Parameter keyPath: 삭제할 항목의 키에 대한 KeyPath입니다.
    func remove<Value>(
        forKey keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Value>>
    ) {
        let key = UserDefaultsKeys()[keyPath: keyPath]
        userDefaults.removeObject(forKey: key.name)
    }
    
    /// `UserDefaults`에 저장된 모든 값을 삭제합니다.
    ///
    /// 이 작업은 앱의 설정을 초기화할 때 유용하게 사용될 수 있습니다.
    func removeAll() {
        userDefaults.dictionaryRepresentation().keys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }
}

extension UserDefaultsWrapper {
    
    subscript<Value>(dynamicMember keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Value>>) -> Value {
        get { get(forKey: keyPath) }
        set { set(forKey: keyPath, value: newValue) }
    }
}
