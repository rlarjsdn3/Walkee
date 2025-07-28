//
//  KeychainWrapper.swift
//  KeychainWrapperProject
//
//  Created by 김건우 on 7/27/25.
//

import Foundation
import Security

/// 키체인 항목의 클래스 정보를 나타냅니다. (예: 일반 비밀번호, 인터넷 비밀번호 등)
let secClass = kSecClass as String

/// 키체인 항목의 서비스 이름을 나타냅니다. 주로 앱의 서비스 식별자와 연결됩니다.
let secAttrService = kSecAttrService as String

/// 키체인 항목의 계정(Account) 이름을 나타냅니다. 사용자 계정 식별 등에 사용됩니다.
let secAttrAccount = kSecAttrAccount as String

/// 키체인 항목의 서버 주소를 나타냅니다. 인터넷 비밀번호 항목에 사용됩니다.
let attrServer = kSecAttrServer as String

/// 저장하거나 조회할 데이터의 실제 값을 나타냅니다.
let secValueData = kSecValueData as String

/// 키체인에서 검색할 항목의 개수 제한을 지정합니다.
let secMatchLimit = kSecMatchLimit as String

/// 검색 결과로 하나의 항목만 가져오도록 설정할 때 사용됩니다.
let secMatchLimitOne = kSecMatchLimitOne as String

/// 키체인 항목 클래스 중 "일반 비밀번호(Generic Password)"에 해당합니다.
let secClassGenericPassword = kSecClassGenericPassword as String

/// 키체인 항목 클래스 중 "인터넷 비밀번호(Internet Password)"에 해당합니다.
let secClassInternetPassword = kSecClassInternetPassword as String

/// 키체인 항목 클래스 중 "인증서(Certificate)"에 해당합니다.
let secClassCertificate = kSecClassCertificate as String

/// 키체인 항목 클래스 중 "암호화 키(Key)"에 해당합니다.
let secClassKey = kSecClassKey as String

/// 키체인 항목 클래스 중 "개인 인증서와 키(Identity)"에 해당합니다.
let secClassIdentity = kSecClassIdentity as String

/// 검색 결과로 데이터 값을 반환하도록 지정할 때 사용됩니다.
let secReturnData = kSecReturnData as String

/// `KeychainError`는 키체인 작업 중 발생할 수 있는 다양한 오류를 정의한 열거형입니다.
/// 오류의 종류별로 구체적인 실패 원인을 식별할 수 있도록 정보를 제공합니다.
enum KeychainError: Error, Hashable {
    
    /// 데이터를 저장하는 데 실패한 경우입니다.
    /// - Parameters:
    ///   - key: 저장하려는 키의 이름입니다.
    ///   - data: 저장을 시도한 데이터입니다. 선택적 값입니다.
    case canNotSave(key: String, data: Data?)
    
    /// 데이터를 불러오는 데 실패한 경우입니다.
    /// - Parameter key: 불러오려는 키의 이름입니다.
    case canNotLoad(key: String)
    
    /// 데이터를 삭제하는 데 실패한 경우입니다.
    /// - Parameter key: 삭제하려는 키의 이름입니다.
    case canNotRemove(key: String)
    
    /// 알 수 없는 상태 코드로 인한 예외적인 오류입니다.
    /// - Parameter status: 시스템에서 반환한 OSStatus 값입니다.
    case unhandledError(status: OSStatus)
}

extension KeychainError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .canNotSave(let key, let data):
            var message = "Can not save data for key: \(key) "
            if let data = data {
                message += "data: \(data)"
            }
            return message
        case .canNotLoad(let key):
            return "Can not load data for key: \(key)"
        case .canNotRemove(let key):
            return "Can not remove data for key: \(key)"
        case .unhandledError(let status):
            return "Keychain unhandled error: \(status)"
        }
    }
}

/// `KeychainWrapper`는 키체인에 안전하게 데이터를 저장하고 불러오기 위한 기능을 제공하는 래퍼 클래스입니다.
/// `@dynamicMemberLookup`를 통해 키에 접근하는 방식을 간편하게 할 수 있으며,
/// 싱글톤 인스턴스를 통해 전역에서 동일한 서비스 이름으로 키체인 작업을 수행할 수 있습니다.
@dynamicMemberLookup
final class KeychainWrapper: @unchecked Sendable {
    
    /// `KeychainWrapper`의 전역 공유 인스턴스입니다.
    /// 기본적으로 앱의 빌드 환경에 따라 서로 다른 서비스 이름을 사용합니다.
    static let shared = KeychainWrapper()
    
    /// 기본 생성자입니다.
    /// `DEBUG` 환경에서는 `"com.debug.KeychainWrapper"`를,
    /// `RELEASE` 환경에서는 `"com.release.KeychainWrapper"`를 서비스 이름으로 사용합니다.
    private init() {
#if DEBUG
        self.service = "com.debug.KeychainWrapper"
#else
        self.service = "com.release.KeychainWrapper"
#endif
    }
    
    /// 지정한 서비스 이름을 기반으로 `KeychainWrapper` 인스턴스를 생성합니다.
    ///
    /// - Parameter service: 키체인에 저장할 때 사용할 고유 서비스 이름입니다.
    init(service: String) {
        self.service = service
    }
    
    /// 키체인 항목에 사용될 서비스 식별자입니다.
    /// 일반적으로 앱 고유의 번들 식별자 등을 기반으로 설정합니다.
    private let service: String
    
    
    // MARK: - Save
    
    /// 인코딩 가능한 값을 지정된 키에 대해 키체인에 저장합니다.
    ///
    /// 내부적으로 `Encodable` 값을 `JSONEncoder`를 통해 `Data`로 변환한 뒤,
    /// 해당 데이터를 키체인에 저장합니다.
    ///
    /// - Parameters:
    ///   - keyPath: `KeychainKeys`에서 정의된 키에 대한 KeyPath입니다.
    ///   - value: 키체인에 저장할 값입니다. `nil`일 경우 해당 항목이 삭제됩니다.
    /// - Throws: 저장에 실패할 경우 `KeychainError`를 던집니다.
    func set<Value>(
        forKey keyPath: KeyPath<KeychainKeys, KeychainKey<Value>>,
        _ value: Value?
    ) throws(KeychainError) where Value: Encodable {
        guard let data = try? JSONEncoder().encode(value)
        else { return }
        
        let key = KeychainKeys()[keyPath: keyPath]
        return try set(forKey: key.name, data)
    }
    
    /// 바이너리 데이터를 지정된 키에 대해 키체인에 저장합니다.
    ///
    /// 이미 같은 키로 저장된 항목이 존재하는 경우, 기존 항목을 먼저 제거한 후 새로 저장합니다.
    /// 저장할 데이터가 `nil`인 경우 해당 항목을 삭제합니다.
    ///
    /// - Parameters:
    ///   - key: 저장할 키 이름입니다.
    ///   - valueData: 키체인에 저장할 데이터입니다. `nil`인 경우 삭제 처리가 됩니다.
    /// - Throws: 저장 또는 삭제에 실패한 경우 `KeychainError`를 던집니다.
    func set(
        forKey key: String,
        _ valueData: Data?
    ) throws(KeychainError) {
        var query = kSecurityQueryDictionary(forKey: key)
        
        if let data = valueData {
            query[secValueData] = data as Any
            
            try? remove(forKey: key)
            let status = SecItemAdd(query as CFDictionary, nil)
            
            if status != errSecSuccess {
                throw .canNotSave(key: key, data: valueData)
            }
        } else {
            try remove(forKey: key)
        }
    }
    
    
    // MARK: - Load
    
    /// 키체인에서 지정된 키에 해당하는 값을 불러와 디코딩하여 반환합니다.
    ///
    /// 내부적으로 키체인에 저장된 `Data` 값을 `JSONDecoder`를 통해 복원하며,
    /// 디코딩이 실패하거나 값이 존재하지 않는 경우 오류를 발생시킵니다.
    ///
    /// - Parameter keyPath: `KeychainKeys`에서 정의된 키에 대한 KeyPath입니다.
    /// - Returns: 키체인에서 디코딩된 값입니다.
    /// - Throws: 값이 존재하지 않거나 디코딩에 실패한 경우 `KeychainError`를 던집니다.
    func get<Value>(
        forKey keyPath: KeyPath<KeychainKeys, KeychainKey<Value>>
    ) throws(KeychainError) -> Value where Value: Decodable {
        let key = KeychainKeys()[keyPath: keyPath]
        let matchingData = try get(forKey: key.name)
        
        guard let value = try? JSONDecoder().decode(Value.self, from: matchingData)
        else { throw .canNotLoad(key: key.name) }
        return value
    }
    
    /// 키체인에서 지정된 키에 해당하는 원시 데이터를 반환합니다.
    ///
    /// 이 메서드는 키체인에 저장된 값을 `Data` 타입으로 직접 가져오며,
    /// 항목이 존재하지 않거나 시스템 오류가 발생한 경우 예외를 던집니다.
    ///
    /// - Parameter key: 검색할 키 이름입니다.
    /// - Returns: 키체인에서 검색된 `Data` 값입니다.
    /// - Throws: 키가 존재하지 않거나 시스템 오류가 발생한 경우 `KeychainError`를 던집니다.
    func get(
        forKey key: String
    ) throws(KeychainError) -> Data {
        var query = kSecurityQueryDictionary(forKey: key)
        query[secMatchLimit] = secMatchLimitOne
        query[secReturnData] = kCFBooleanTrue
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status != errSecSuccess || status == errSecItemNotFound {
            throw .canNotLoad(key: key)
        }
        
        guard let safeData = result as? Data
        else { throw .canNotLoad(key: key) }
        return safeData
    }
    
    
    // MARK: - Delete
    
    /// 지정한 키에 해당하는 값을 키체인에서 삭제합니다.
    ///
    /// `KeychainKeys`에 정의된 키를 기반으로 항목을 식별하여 삭제를 시도합니다.
    ///
    /// - Parameter keyPath: 삭제할 항목의 키에 대한 KeyPath입니다.
    /// - Throws: 삭제에 실패한 경우 `KeychainError`를 던집니다.
    func remove<Value>(
        forKey keyPath: KeyPath<KeychainKeys, KeychainKey<Value>>
    ) throws(KeychainError) {
        let key = KeychainKeys()[keyPath: keyPath]
        try remove(forKey: key.name)
    }
    
    /// 지정한 키에 해당하는 값을 키체인에서 직접 삭제합니다.
    ///
    /// 내부적으로 `SecItemDelete`를 호출하여 삭제를 수행합니다.
    ///
    /// - Parameter key: 삭제할 항목의 키 이름입니다.
    /// - Throws: 삭제에 실패한 경우 `KeychainError`를 던집니다.
    func remove(forKey key: String) throws(KeychainError) {
        let query = kSecurityQueryDictionary(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess {
            throw .canNotRemove(key: key)
        }
    }
    
    /// 키체인에 저장된 모든 항목을 삭제합니다.
    ///
    /// `GenericPassword`, `InternetPassword`, `Certificate`, `Key`, `Identity` 등
    /// 주요 키체인 클래스에 해당하는 항목을 순회하며 모두 제거합니다.
    ///
    /// - Throws: 삭제 중 시스템 오류가 발생한 경우 `KeychainError.unhandledError`를 던집니다.
    func removeAll() throws {
        try [secClassGenericPassword,
             secClassInternetPassword,
             secClassCertificate,
             secClassKey,
             secClassIdentity]
            .forEach {
                let status = SecItemDelete(
                    [secClass: $0] as CFDictionary
                )
                if status != errSecSuccess && status != errSecItemNotFound {
                    throw KeychainError.unhandledError(status: status)
                }
            }
    }
}

extension KeychainWrapper {
    
    /// 주어진 계정(account) 값을 기반으로 키체인에 접근하기 위한 쿼리 딕셔너리를 생성합니다.
    ///
    /// - Parameter account: 키체인 항목의 계정(account) 이름입니다. 일반적으로 키로 사용됩니다.
    /// - Returns: 키체인 접근을 위한 표준 형식의 `[String: Any]` 쿼리 딕셔너리를 반환합니다.
    private func kSecurityQueryDictionary(forKey account: String) -> [String: Any] {
        [secClass: secClassGenericPassword,
         secAttrService: service as AnyObject,
         secAttrAccount: account as AnyObject]
    }
}

extension KeychainWrapper {
    
    subscript<Value>(dynamicMember keyPath: KeyPath<KeychainKeys, KeychainKey<Value>>) -> Value? where Value: Codable {
        get { try? get(forKey: keyPath) }
        set { try? set(forKey: keyPath, newValue) }
    }
}
