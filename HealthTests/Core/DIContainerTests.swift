//
//  DIContainerTests.swift
//  HealthTests
//
//  Created by 김건우 on 7/29/25.
//

import XCTest
@testable import Health

@MainActor
final class DIContainerProjectTests: XCTestCase {

    private var sut: DIContainer!

    override func setUp() {
        sut = DIContainer(identifier: "com.test.dicontainer")
    }

    override func tearDown() {
        sut.removeAllDependencies()
    }

    func testDIContainer_WhenResolvingUnavailableDependency_ThenThrowError() {
        // given
        struct Mock: Equatable { }
        let identifier: InjectIdentifier = .by(type: Mock.self)

        // then
        XCTAssertThrowsError(try sut.resolve(identifier))
    }

    func testDIContainer_WhenRegisteringWithType_ThenResolveDedepencyCorrectly() {
        // given
        struct Mock: Equatable { }
        let mock = Mock()

        // when
        sut.register(type: Mock.self) { _ in mock }

        // then
        let resolvedMock = try! sut.resolve(type: Mock.self)
        XCTAssertEqual(mock, resolvedMock)
    }

    func testDIContainer_WhenRegisteringWithTypeAndName_ThenResolveDedenpencyCorrectly() {
        // given
        struct Mock: Equatable { }
        let mock = Mock()

        // when
        sut.register(type: Mock.self, name: "mock") { _ in mock }

        // then
        let resolvedMock = try! sut.resolve(type: Mock.self, name: "mock")
        XCTAssertEqual(mock, resolvedMock)
    }

    func testDIContainer_WhenRegisteringWithIdentifier_ThenResolveDedepencyCorrectly() {
        // given
        struct Mock: Equatable { }

        let mock = Mock()
        let identifier = InjectIdentifier.by(type: Mock.self, name: "mock")

        // when
        sut.register(identifier) { _ in  mock }

        // then
        let dep = sut.dependencies[identifier] as! Mock
        XCTAssertEqual(dep, mock)
        let resolvedMock = try! sut.resolve(identifier)
        XCTAssertEqual(mock, resolvedMock)
    }

    func testDIContainer_WhenRegisteringWithNestedResolve_ThenResolvesAllDependenciesCorrectly() {
        // givne
        struct ViewModel: Equatable { let networkService: NetworkService }
        struct NetworkService: Equatable { }

        let networkService = NetworkService()
        let viewModel = ViewModel(networkService: networkService)

        // when
        sut.register(type: NetworkService.self) { _ in networkService }
        sut.register(type: ViewModel.self) { resolver in
            let networkService = try! resolver.resolve(.by(type: NetworkService.self))
            return ViewModel(networkService: networkService)
        }

        // then
        let resolvedNetworkService = try! sut.resolve(type: NetworkService.self)
        XCTAssertEqual(networkService, resolvedNetworkService)
        let resolvedViewModel = try! sut.resolve(type: ViewModel.self)
        XCTAssertEqual(resolvedViewModel, viewModel)
    }

    func testDIContainer_WhenRemoveRegisteredDependency_ThenRemoveItCorrectly() {
        // given
        struct Mock: Equatable { }
        let mock = Mock()

        // when
        sut.register(.by(type: Mock.self)) { _ in mock }

        // then
        let resolvedMock = try! sut.resolve(.by(type: Mock.self))
        XCTAssertEqual(resolvedMock, mock)
        sut.remove(.by(type: Mock.self))
        XCTAssertThrowsError(try sut.resolve(.by(type: Mock.self)))
    }

    func testDIContainer_WhenRemoveAllRegisteredDependencies_ThenRemoveAllCorrectly() {
        // given
        let intIdentifier = InjectIdentifier.by(type: Int.self, name: "IntValue")
        let stringIdentifier = InjectIdentifier.by(type: String.self)

        // when
        sut.register(intIdentifier) { _ in 777 }
        sut.register(stringIdentifier) { _ in "Hello, World!" }

        // then
        sut.removeAllDependencies()
        XCTAssertThrowsError(try sut.resolve(intIdentifier)) { error in
            if let error = error as? ResolvableError {
                XCTAssertEqual(error, .dependencyNotFound(Int.self, "IntValue"))
                XCTAssertEqual(error.errorDescription, "Could not find dependency for type: Int, key: IntValue")
            }
        }
        XCTAssertThrowsError(try sut.resolve(stringIdentifier)) { error in
            if let error = error as? ResolvableError {
                XCTAssertEqual(error, .dependencyNotFound(String.self, nil))
                XCTAssertEqual(error.errorDescription, "Could not find dependency for type: String")
            }
        }
    }

    func testDIContainer_WhenUsingInjectedPropertyAnnotation_ThenResolvesExpectedDependency() {
        // given
        class Mock {
            @Injected(.by(type: String.self))
            var text: String
            init(sut: DIContainer) {
                _text.updateContainer(sut)
            }
        }
        let helloText = "Hello, World!"

        // given
        sut.register(.by(type: String.self)) { _ in helloText }

        // then
        let mock = Mock(sut: sut)
        XCTAssertEqual(mock.text, helloText)
    }

    func testDIContainer_WhenInjectValueToInjectedPropertyAnnotation_ThenUsesInjectedValueInsteadOfResolving() {
        // given
        protocol Wrapper { }
        struct DefaultWrapper: Wrapper, Equatable { var number: Int }

        class WrapperClass {
            @Injected(.by(type: Wrapper.self))
            var wrapper: any Wrapper
            init(sut: DIContainer, wrapper: any Wrapper) {
                _wrapper.updateContainer(sut)
                self.wrapper = wrapper
            }
        }

        // when
        sut.register(.by(type: Wrapper.self)) { _ in DefaultWrapper(number: 123) }

        // then
        let wrapper = DefaultWrapper(number: 777)
        let mock = WrapperClass(sut: sut, wrapper: wrapper)
        XCTAssertEqual(mock.wrapper as! DefaultWrapper, wrapper)
    }

    func testDIContainer_WhenFailedToResolveInjectedPropertyAnnotation_ThenReturnDefaultValueInstead() {
        // when
        let defaultValue = "Hello, It's DefaultValue!"
        @Injected(.by(type: String.self), default: defaultValue) var stringValue: String

        // then
        XCTAssertEqual(stringValue, defaultValue)
    }
}
