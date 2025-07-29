//
//  KeychainWrapperProjectTests.swift
//  KeychainWrapperProjectTests
//
//  Created by 김건우 on 7/27/25.
//

import XCTest
@testable import Health

final class KeychainWrapperProjectTests: XCTestCase {
    
    private let service: String = "com.test.KeychainWrapper"
    
    func testKeychain_WhenLoadingEmptyStringValue_ThenThrowCanNotLoadError() {
        // given
        let keychain = KeychainWrapper(service: service)
        
        // then
        XCTAssertThrowsError(try keychain.get(forKey: \.stringValue)) { error in
            if let error = error as? KeychainError {
                XCTAssertEqual(error, .canNotLoad(key: "string"))
            }
        }
        
        addTeardownBlock { try keychain.removeAll() }
    }
    
    func testKeychain_WhenSavingStringValue_ThenLoadStringValueSuccessfully() {
        // given
        let keychain = KeychainWrapper(service: service)
        let text = "Hello, World!"
        
        // when
        do { try keychain.set(forKey: \.stringValue, text) }
        catch { XCTFail("Can not save value: \(error)") }
    
        // then
        guard let loadedText: String = try? keychain.get(forKey: \.stringValue)
        else { XCTNever("Can not load value") }
        XCTAssertEqual(text, loadedText)
        
        addTeardownBlock { try keychain.removeAll() }
    }

    func testKeychain_WhenSavingStringValueMultipleTimes_ThenLoadLastOverwrittenStringValueSuccessfully() {
        // given
        let keychain = KeychainWrapper(service: service)
        let text = "Hello, UIKit!"
        let overwrittenText = "Hello, Swift!"

        // when
        do { try keychain.set(forKey: \.stringValue, text)
            try keychain.set(forKey: \.stringValue, overwrittenText) }
        catch { XCTFail("Can not save value: \(error)") }

        // then
        guard let loadedText: String = try? keychain.get(forKey: \.stringValue)
        else { XCTNever("Can not load value") }
        XCTAssertEqual(loadedText, overwrittenText)

        addTeardownBlock { try keychain.removeAll() }
    }

    func testKeychain_WhenRemovingStringValue_ThenCanNotLoadStringValue() {
        // given
        let keychain = KeychainWrapper(service: service)
        let text = "Hello, Keychain!"
        
        do { try keychain.set(forKey: \.stringValue, text) }
        catch { XCTFail("Can not save value: \(error)") }

        // when
        XCTAssertNoThrow(try keychain.remove(forKey: \.stringValue))

        // then
        XCTAssertThrowsError(try keychain.get(forKey: \.stringValue)) { error in
            if let error = error as? KeychainError {
                XCTAssertEqual(error, .canNotLoad(key: "string"))
            }
        }
        
        addTeardownBlock { try keychain.removeAll() }
    }

    func testKeychain_WhenLoadingEmptyIntegerValueUsingKeychainStorage_ThenReturnNil() {
        // given
        let keychain = KeychainWrapper(service: service)

        // when
        @KeychainStorage(\.integerValue, on: keychain) var integerValue: Int?

        // then
        XCTAssertNil(integerValue)

        addTeardownBlock { try keychain.removeAll() }
    }

    func testKeychain_WhenSavingIntegerValueUsingKeychainStorage_ThenLoadIntegerValueSuccessfully() {
        // given
        let keychain = KeychainWrapper(service: service)
        let number = 777

        do { try keychain.set(forKey: \.integerValue, number) }
        catch { XCTFail("Can not save value: \(error)") }

        // when
        @KeychainStorage(\.integerValue, on: keychain) var integerValue: Int?

        // then
        XCTAssertEqual(integerValue, number)
    }

    func testKeychain_WhenSavingStringValueUsingKeychainStorageMultipleTimes_ThenLoadLastOverwrittenStringValueSuccessfully() {
        // given
        let keychain = KeychainWrapper(service: service)
        let number = 111
        let overwrittenNumber = 222

        // when
        @KeychainStorage(\.integerValue, on: keychain)
        var integerValue: Int?
        integerValue = number
        integerValue = overwrittenNumber

        // then
        guard let loadedNumber: Int = try? keychain.get(forKey: \.integerValue)
        else { XCTNever("Can not load value") }
        XCTAssertEqual(loadedNumber, overwrittenNumber)

        addTeardownBlock { try keychain.removeAll() }
    }

    func testKeychain_WhenAssignNilToKeychainStorage_ThenRemoveIntegerValue() {
        // given
        let keychain = KeychainWrapper(service: service)

        do { try keychain.set(forKey: \.integerValue, 777) }
        catch { XCTFail("Can not save value: \(error)") }

        // when
        @KeychainStorage(\.integerValue, on: keychain) var integerValue: Int?
        integerValue = nil

        // then
        XCTAssertNil(integerValue)
    }

    func testKeychain_WhenRemovingAllValues_ThenRemoveAllValuesProperly() {
        // given
        let keychain = KeychainWrapper(service: service)

        do { try keychain.set(forKey: \.integerValue, 777)
             try keychain.set(forKey: \.stringValue, "Hello, World!") }
        catch { XCTFail("Can not save value: \(error)") }

        // then
        do { try keychain.removeAll() }
        catch { XCTFail("Can not remove value: \(error)") }

        // when
        XCTAssertNil(try? keychain.get(forKey: \.integerValue))
        XCTAssertNil(try? keychain.get(forKey: \.stringValue))
    }
}

extension KeychainKeys {

    var stringValue: KeychainKey<String> { "string" }
    var integerValue: KeychainKey<Int> { "int" }
}


fileprivate extension XCTestCase {

    /// 테스트 도중 절대로 도달해서는 안 되는 지점에 도달했음을 나타내며, 테스트를 즉시 실패 처리합니다.
    ///
    /// 일반적으로 `Result` 처리나 불변 조건 검증 등에서 사용됩니다.
    ///
    /// - Parameter message: 실패 원인 또는 디버깅 메시지를 입력할 수 있습니다.
    /// - Returns: 호출 즉시 `fatalError`를 발생시키므로 반환되지 않습니다.
    func XCTNever(_ message: String = "") -> Never {
        fatalError(message)
    }
}
