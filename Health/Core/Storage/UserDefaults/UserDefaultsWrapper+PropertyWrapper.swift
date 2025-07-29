//
//  UserDefaultsWrapper+PropertyWrapper.swift
//  UserDefaultsWrapperProject
//
//  Created by 김건우 on 7/26/25.
//

import Foundation

/// `AppStorage`는 `UserDefaultsWrapper`를 통해 사용자 설정 값을 간편하게 저장하고 가져올 수 있도록 도와주는 프로퍼티 래퍼입니다.
///
/// SwiftUI의 `@AppStorage`와 유사한 방식으로 동작하며, 키와 기본값을 지정하여 안전하게 값을 관리할 수 있습니다.
@propertyWrapper
struct AppStorage<Value> {
    private let storage: UserDefaultsWrapper
    private let keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Value>>
    
    /// 지정된 기본값을 설정하고, 해당 키를 기반으로 저장소를 초기화합니다.
    ///
    /// - Parameters:
    ///   - defaultVaue: 값이 존재하지 않을 경우 사용할 기본값입니다.
    ///   - keyPath: `UserDefaultsKeys`에서 정의한 항목에 대한 KeyPath입니다.
    ///   - storage: 값을 저장하고 불러올 때 사용할 `UserDefaultsWrapper`입니다. 기본값은 `.shared`입니다.
    init(
        wrappedValue defaultVaue: Value,
        _ keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Value>>,
        on storage: UserDefaultsWrapper = .shared
    ) {
        self.init(keyPath, on: storage)
        storage.set(forKey: keyPath, value: defaultVaue)
    }
    
    /// 지정된 키를 기반으로 값을 관리할 수 있도록 래퍼를 초기화합니다.
    ///
    /// - Parameters:
    ///   - keyPath: `UserDefaultsKeys`에서 정의한 항목에 대한 KeyPath입니다.
    ///   - storage: 사용할 `UserDefaultsWrapper` 인스턴스입니다. 기본값은 `.shared`입니다.
    init(
        _ keyPath: KeyPath<UserDefaultsKeys, UserDefaultsKey<Value>>,
        on storage: UserDefaultsWrapper = .shared
    ) {
        self.keyPath = keyPath
        self.storage = storage
    }

    /// 프로퍼티에 접근할 때 사용되는 값입니다.
    /// 값을 가져올 때는 `UserDefaults`에서 읽어오며, 설정 시에는 자동으로 저장됩니다.
    var wrappedValue: Value {
        get { storage.get(forKey: keyPath) }
        set { storage.set(forKey: keyPath, value: newValue) }
    }
}

extension AppStorage {

    /// 해당 키에 저장된 값을 `UserDefaults`에서 삭제합니다.
    ///
    /// 이 메서드는 사용자 설정을 초기화하거나 필요 없는 값을 제거할 때 사용할 수 있습니다.
    func remove() {
        storage.remove(forKey: keyPath)
    }
}
