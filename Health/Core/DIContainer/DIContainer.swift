//
//  DIContainer.swift
//  DIContainerProject
//
//  Created by 김건우 on 7/26/25.
//

import Foundation

/// 의존성 주입 컨테이너에 객체를 등록할 수 있도록 정의한 프로토콜입니다.
///
/// 이 프로토콜을 채택하면 특정 키나 이름을 기준으로 객체를 주입할 수 있으며,
/// 등록된 객체는 나중에 `Resolvable`을 통해 가져올 수 있습니다.
@MainActor
protocol Injectable {

    /// 주어진 식별자 키를 통해 객체를 등록합니다.
    ///
    /// - Parameters:
    ///   - key: 객체를 고유하게 식별할 수 있는 `InjectIdentifier`입니다.
    ///   - resolve: 객체를 생성하는 클로저입니다. 컨테이너(Resolvable)를 인자로 받습니다.
    func register<Value>(
        _ key: InjectIdentifier<Value>,
        _ resolve: (any Resolvable) -> Value
    )

    /// 타입과 선택적인 이름을 함께 사용하여 객체를 등록합니다.
    ///
    /// - Parameters:
    ///   - type: 등록할 객체의 타입입니다.
    ///   - name: 동일한 타입에 대해 이름으로 구분하고자 할 때 사용하는 선택적 식별자입니다.
    ///   - resolve: 객체를 생성하는 클로저입니다. 컨테이너(Resolvable)를 인자로 받습니다.
    func register<Object>(
        type: Object.Type,
        name: String?,
        _ resolve: (any Resolvable) -> Object
    )
}

/// 의존성 주입 컨테이너에서 객체를 조회하는 기능을 정의한 프로토콜입니다.
///
/// 이 프로토콜을 채택하면 등록된 타입 또는 식별자를 기준으로
/// 필요한 객체를 안전하게 가져올 수 있습니다.
@MainActor
protocol Resolvable {

    /// 주어진 식별자 키를 사용하여 객체를 조회합니다.
    ///
    /// 이 메서드는 `InjectIdentifier<Object>`를 기반으로 객체를 식별하여 반환합니다.
    ///
    /// - Parameter key: 조회할 객체를 식별하는 키입니다.
    /// - Returns: 식별자에 해당하는 객체 인스턴스를 반환합니다.
    /// - Throws: 등록된 객체가 없거나 조회에 실패한 경우 예외를 던집니다.
    func resolve<Value>(_ key: InjectIdentifier<Value>) throws -> Value

    /// 타입과 이름을 기반으로 객체를 조회합니다.
    ///
    /// 동일한 타입이 여러 개 등록된 경우, 이름(`name`)을 통해 특정 객체를 구분할 수 있습니다.
    ///
    /// - Parameters:
    ///   - type: 조회할 객체의 타입입니다.
    ///   - name: 동일한 타입의 객체를 구분하기 위한 선택적 식별 이름입니다.
    /// - Returns: 요청한 타입과 이름에 해당하는 객체 인스턴스를 반환합니다.
    /// - Throws: 등록된 객체가 없거나 조회에 실패한 경우 예외를 던집니다.
    func resolve<Object>(
        type: Object.Type,
        name: String?
    ) throws -> Object
}

/// 의존성 주입 컨테이너에서 객체를 조회할 때 발생할 수 있는 오류를 정의한 열거형입니다.
enum ResolvableError: Error {

    /// 요청한 타입과 이름에 해당하는 의존성이 등록되어 있지 않은 경우 발생하는 오류입니다.
    ///
    /// - Parameters:
    ///   - type: 조회를 시도한 객체의 타입입니다.
    ///   - name: (선택 사항) 구분용으로 지정된 이름입니다. 없을 경우 `nil`입니다.
    case dependencyNotFound(Any.Type, String?)
}

extension ResolvableError: Hashable {

    static func == (lhs: ResolvableError, rhs: ResolvableError) -> Bool {
        switch (lhs, rhs) {
        case (.dependencyNotFound(let lhsType, let lhsKey),
              .dependencyNotFound(let rhsType, let rhsKey)):
            return lhsType == rhsType && lhsKey == rhsKey
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .dependencyNotFound(let any, let string):
            hasher.combine(ObjectIdentifier(any))
            if let string = string {
                hasher.combine(string)
            }
        }
    }
}

extension ResolvableError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case let .dependencyNotFound(type, key):
            var message = "Could not find dependency for type: \(type)"
            if let key = key {
                message += ", key: \(key)"
            }
            return message
        }
    }
}

/// 의존성 주입 컨테이너에서 등록된 객체를 제거하는 기능을 정의한 프로토콜입니다.
///
/// 이 프로토콜을 채택하면 개별 객체 또는 전체 의존성을 제거할 수 있어,
/// 테스트 환경이나 상태 초기화에 유용하게 활용됩니다.
@MainActor
protocol Removable {

    /// 지정된 식별자 키를 통해 등록된 객체를 제거합니다.
    ///
    /// - Parameter key: 제거할 객체를 식별하는 `InjectIdentifier`입니다.
    func remove<Value>(_ key: InjectIdentifier<Value>)

    /// 타입과 이름을 기반으로 등록된 객체를 제거합니다.
    ///
    /// - Parameters:
    ///   - type: 제거할 객체의 타입입니다.
    ///   - name: 동일한 타입의 여러 인스턴스를 구분하기 위한 선택적 식별 이름입니다.
    func remove<Object>(
        type: Object.Type,
        name: String?
    )

    /// 컨테이너에 등록된 모든 의존성을 제거합니다.
    ///
    /// 주로 테스트나 재초기화 용도로 사용되며,
    /// 이후에는 다시 `register`를 통해 의존성을 등록해야 합니다.
    func removeAllDependencies()
}

/// `DIContainer`는 의존성 주입(Dependency Injection)을 위한 핵심 컨테이너 클래스입니다.
///
/// 객체를 등록(`register`), 조회(`resolve`), 제거(`remove`)할 수 있으며,
/// 싱글톤 인스턴스를 통해 앱 전역에서 의존성을 관리할 수 있습니다.
@MainActor
final class DIContainer {

    /// `DIContainer`의 전역 공유 인스턴스입니다.
    ///
    /// 앱 전체에서 하나의 컨테이너를 사용하도록 싱글톤으로 구성되어 있습니다.
    static let shared = DIContainer()
    private init() {
        self.identifier = "com.allen.dicontainer"
    }

    /// 이 컨테이너의 고유 식별자입니다.
    ///
    /// 주로 디버깅이나 테스트 시 여러 컨테이너 인스턴스를 구분하는 데 사용됩니다.
    private(set) var identifier: String

    /// 식별자를 직접 지정하여 새로운 `DIContainer` 인스턴스를 생성합니다.
    ///
    /// - Parameter identifier: 컨테이너를 구분하기 위한 고유 문자열입니다.
    init(identifier: String) {
        self.identifier = identifier
    }

    /// 현재 컨테이너에 등록된 모든 의존성 객체를 저장하는 딕셔너리입니다.
    ///
    /// 키는 `InjectIdentifier`로부터 생성된 `AnyHashable`이며,
    /// 값은 등록된 객체 인스턴스입니다.
    private(set) var dependencies: [AnyHashable: Any] = [:]
}

extension DIContainer: Injectable {

    /// 타입과 이름을 기반으로 객체를 등록합니다.
    ///
    /// 이 메서드는 내부적으로 `InjectIdentifier`를 생성하여 객체를 등록하며,
    /// 동일한 타입의 객체를 이름(`name`)으로 구분할 수 있습니다.
    ///
    /// - Parameters:
    ///   - type: 등록할 객체의 타입입니다.
    ///   - name: 동일한 타입의 객체를 구분하기 위한 선택적 식별 이름입니다.
    ///   - resolve: 컨테이너를 인자로 받아 객체를 생성하는 클로저입니다.
    func register<Value>(
        type: Value.Type,
        name: String? = nil,
        _ resolve: (any Resolvable) -> Value
    ) {
        self.register(.by(type: type, name: name), resolve)
    }

    /// 주어진 식별자 키를 사용하여 객체를 등록합니다.
    ///
    /// 등록된 객체는 내부 `dependencies` 딕셔너리에 저장되며,
    /// 이후 `resolve` 메서드를 통해 조회할 수 있습니다.
    ///
    /// - Parameters:
    ///   - key: 객체를 고유하게 식별하는 `InjectIdentifier`입니다.
    ///   - resolve: 컨테이너를 인자로 받아 객체를 생성하는 클로저입니다.
    func register<Value>(
        _ key: InjectIdentifier<Value>,
        _ resolve: (any Resolvable) -> Value
    ) {
        dependencies[key] = resolve(self)
    }
}

extension DIContainer: Resolvable {

    /// 타입과 이름을 기반으로 객체를 조회합니다.
    ///
    /// 이 메서드는 `InjectIdentifier`를 사용하여 객체를 찾으며, 객체가 없으면 `ResolvableError.dependencyNotFound` 오류를 던집니다.
    ///
    /// - Parameters:
    ///   - type: 조회할 객체의 타입입니다.
    ///   - name: 동일한 타입의 객체를 구분하기 위한 선택적 식별 이름입니다.
    /// - Returns: 조회된 객체를 반환합니다.
    /// - Throws: 해당 타입과 이름을 가진 객체가 없으면 `ResolvableError.dependencyNotFound`를 던집니다.
    func resolve<Value>(
        type: Value.Type,
        name: String? = nil
    ) throws -> Value {
        return try resolve(.by(type: type, name: name))
    }

    /// 주어진 `InjectIdentifier`를 기반으로 객체를 조회합니다.
    ///
    /// 객체가 존재하지 않으면 `ResolvableError.dependencyNotFound` 오류를 던집니다.
    ///
    /// - Parameter key: 객체를 고유하게 식별하는 `InjectIdentifier`입니다.
    /// - Returns: 조회된 객체를 반환합니다.
    /// - Throws: 해당 식별자에 맞는 객체가 없으면 `ResolvableError.dependencyNotFound`를 던집니다.
    func resolve<Value>(_ key: InjectIdentifier<Value>) throws(ResolvableError) -> Value {
        guard let object = dependencies[key] as? Value else {
            throw .dependencyNotFound(Value.self, key.name)
        }
        return object
    }
}

extension DIContainer: Removable {

    /// 주어진 식별자 키에 해당하는 객체를 의존성 목록에서 제거합니다.
    ///
    /// - Parameter key: 제거할 객체를 식별하는 `InjectIdentifier`입니다.
    func remove<Value>(_ key: InjectIdentifier<Value>) {
        dependencies[key] = nil
    }

    /// 타입과 선택적인 이름을 사용하여 등록된 객체를 제거합니다.
    ///
    /// 내부적으로 `InjectIdentifier`를 생성하여 해당 항목을 제거합니다.
    ///
    /// - Parameters:
    ///   - type: 제거할 객체의 타입입니다.
    ///   - name: 동일한 타입의 여러 객체를 구분하기 위한 선택적 식별 이름입니다.
    func remove<Value>(
        type: Value.Type,
        name: String? = nil
    ) {
        self.remove(.by(type: type, name: name))
    }

    /// 현재 등록된 모든 의존성 객체를 제거합니다.
    ///
    /// 주로 테스트 종료 후 초기화하거나, DI 컨테이너를 재설정할 때 사용됩니다.
    func removeAllDependencies() {
        self.dependencies.removeAll()
    }
}
