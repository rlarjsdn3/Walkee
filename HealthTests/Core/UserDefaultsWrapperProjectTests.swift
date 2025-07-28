//
//  UserDefaultsWrapperProjectTests.swift
//  UserDefaultsWrapperProjectTests
//
//  Created by 김건우 on 7/26/25.
//

import XCTest
@testable import Health

final class UserDefaultsWrapperTests: XCTestCase {

    var sut: UserDefaults!

    override func setUp() {
        sut = UserDefaults(suiteName: "com.test.userDefaultsWrapper")
    }

    override func tearDown() {
        sut.dictionaryRepresentation().keys.forEach { sut.removeObject(forKey: $0) }
    }

    func testUserDefaults_WhenLoadIntegerValue_ThenLoadDefaultValue() {
        // given
        let wrapper = UserDefaultsWrapper(userDefaults: sut)

        // then
        XCTAssertEqual(wrapper.integerValue, 0)
        XCTAssertEqual(wrapper.get(forKey: \.integerValue), 0)
    }

    func testUserDefaults_WhenSaveIntegerValue_ThenSaveSuccessfully() {
        // given
        let wrapper = UserDefaultsWrapper(userDefaults: sut)

        // then
        XCTAssertEqual(wrapper.integerValue, 0)
        [100, 200].forEach { integer in
            wrapper.integerValue = integer
            XCTAssertEqual(wrapper.integerValue, integer)
        }

        [300, 400].forEach { integer in
            wrapper.set(forKey: \.integerValue, value: integer)
            XCTAssertEqual(wrapper.get(forKey: \.integerValue), integer)
        }
    }

    func testUserDefaults_WhenRemoveIntegerValue_ThenRemoveSuccessfully() {
        // given
        let wrapper = UserDefaultsWrapper(userDefaults: sut)

        // when
        wrapper.integerValue = 100
        wrapper.remove(forKey: \.integerValue)

        // then
        XCTAssertEqual(wrapper.integerValue, 0)
    }

    func testUserDefaults_WhenLoadIntegerValueUsingAppStorage_ThenLoadDefaultValue() {
        // given
        let wrapper = UserDefaultsWrapper(userDefaults: sut)

        // then
        @AppStorage(\.integerValue, on: wrapper) var integerValue: Int
        XCTAssertEqual(integerValue, 0)
    }

    func testUserDefaults_WhenSaveIntegerValueUsingAppStorage_ThenSaveSuccessfully() {
        // given
        let wrapper = UserDefaultsWrapper(userDefaults: sut)

        // then
        @AppStorage(\.integerValue, on: wrapper) var integerValue: Int
        [100, 200, 300].forEach { integer in
            integerValue = integer
            XCTAssertEqual(integerValue, integer)
        }
    }

    func testUserDefaults_WhenSaveIntegerValueUsingAppStorageWithIntialValue_ThenLoadIntialValueSuccessfully() {
        // given
        let wrapper = UserDefaultsWrapper(userDefaults: sut)

        // when
        @AppStorage(\.integerValue, on: wrapper) var integerValue: Int = 500

        // then
        XCTAssertEqual(integerValue, 500)
    }

    func testUserDefaults_WhenRemoveIntegerValueUsingAppStorage_ThenRemoveSuccessfully() {
        // given
        let wrapper = UserDefaultsWrapper(userDefaults: sut)

        // when
        @AppStorage(\.integerValue, on: wrapper) var integerValue: Int = 100
        _integerValue.remove()

        // then
        XCTAssertEqual(integerValue, 0)
    }
}

fileprivate extension UserDefaultsKeys {

    var integerValue: UserDefaultsKey<Int> {
        UserDefaultsKey("integerValue", defaultValue: 0)
    }
}
