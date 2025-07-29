//
//  KeychainWrapper+PropertyWrapper.swift
//  KeychainWrapperProject
//
//  Created by 김건우 on 7/27/25.
//

import Foundation

/// 키체인에 값을 안전하게 저장하고 불러오기 위한 프로퍼티 래퍼입니다.
///
/// 이 래퍼는 `Codable`을 따르는 값을 자동으로 `KeychainWrapper`를 통해 저장 및 조회할 수 있도록 도와줍니다.
///
/// - Important: 이 프로퍼티 래퍼는 예외를 던질 수 없기 때문에, 값을 사용할 때는 반드시 옵셔널(`Value?`) 형태로 처리해 주시기 바랍니다.
///              저장 및 불러오기에 실패할 경우 `nil`이 반환되며, 내부적으로 오류는 무시됩니다.
@propertyWrapper
struct KeychainStorage<Value> where Value: Codable {
    private let keyPath: KeyPath<KeychainKeys, KeychainKey<Value>>
    private let storage: KeychainWrapper
    
    /// 주어진 기본값을 키체인에 저장하면서 초기화합니다.
    ///
    /// - Parameters:
    ///   - defaultValue: 키체인에 기본적으로 저장할 값입니다.
    ///   - keyPath: `KeychainKeys`에서 정의된 항목에 대한 KeyPath입니다.
    ///   - storage: 값을 저장할 `KeychainWrapper` 인스턴스입니다. 기본값은 `.shared`입니다.
    init(
        wrappedValue defaultValue: Value,
        _ keyPath: KeyPath<KeychainKeys, KeychainKey<Value>>,
        on storage: KeychainWrapper = .shared
    ) {
        self.init(keyPath, on: storage)
        try? storage.set(forKey: keyPath, defaultValue)
    }
    
    /// 키체인에서 값을 불러오거나 저장할 수 있도록 프로퍼티 래퍼를 초기화합니다.
    ///
    /// - Parameters:
    ///   - keyPath: `KeychainKeys`에서 정의된 항목에 대한 KeyPath입니다.
    ///   - storage: 값을 저장할 `KeychainWrapper` 인스턴스입니다. 기본값은 `.shared`입니다.
    init(
        _ keyPath: KeyPath<KeychainKeys, KeychainKey<Value>>,
        on storage: KeychainWrapper = .shared
    ) {
        self.keyPath = keyPath
        self.storage = storage
    }

    /// 키체인에서 가져온 값을 반환하거나 새 값을 저장합니다.
    ///
    /// 값이 존재하지 않거나 디코딩에 실패한 경우 `nil`이 반환됩니다.
    /// 값 설정 시 저장 실패가 발생하더라도 오류는 무시됩니다.
    var wrappedValue: Value? {
        get { try? storage.get(forKey: keyPath) }
        set { try? storage.set(forKey: keyPath, newValue) }
    }
}

extension KeychainStorage {
    
    /// 현재 키에 해당하는 값을 키체인에서 삭제합니다.
    ///
    /// - Throws: 삭제 과정에서 오류가 발생할 경우 `KeychainError`를 던질 수 있습니다.
    func remove() throws {
        try storage.remove(forKey: keyPath)
    }
}
