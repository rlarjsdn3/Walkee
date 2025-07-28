//
//  DIContainer+PropertyWrapper.swift
//  DIContainerProject
//
//  Created by 김건우 on 7/26/25.
//

import Foundation

/// 등록된 의존성을 간편하게 주입받을 수 있도록 도와주는 프로퍼티 래퍼입니다.
///
/// 내부적으로 `DIContainer`를 통해 객체를 조회하며,
/// 필요 시 기본값을 설정하거나 테스트 목적의 컨테이너를 지정할 수 있습니다.
///
/// - Important: `DIContainer`에 등록되지 않은 의존성을 가져오려고 하면 앱이 크래시됩니다.
///              이는 의존성 누락을 조기에 감지하기 위한 의도된 동작입니다.
@MainActor @propertyWrapper
struct Injected<Value> {

    /// 주입에 사용할 식별자입니다. 타입 또는 이름 기반으로 생성됩니다.
    var identifier: InjectIdentifier<Value>

    /// 의존성을 관리하는 컨테이너입니다. 기본값은 `.shared`입니다.
    var container: DIContainer

    /// 기본값이 지정된 경우, 의존성 대신 반환되는 값입니다.
    var defaultValue: Value?

    /// 식별자와 컨테이너를 기반으로 `Injected`를 초기화합니다.
    ///
    /// 의존성 주입에 실패할 경우 `default`로 지정한 값이 대신 반환됩니다.
    /// 만약 의존성 주입에도 실패하고 `default` 값도 지정되어 있지 않다면, 앱이 크래시됩니다.
    ///
    /// - Parameters:
    ///   - identifier: 의존성을 식별하기 위한 `Inj4ectIdentifier`입니다. 지정하지 않으면 타입 기반으로 자동 생성됩니다.
    ///   - container: 사용할 DI 컨테이너입니다. 기본값은 `.shared`입니다.
    ///   - defaultValue: 의존성 주입에 실패했을 경우 사용할 기본값입니다. 지정하지 않으면 `nil`입니다.
    init(
        _ identifier: InjectIdentifier<Value>? = nil,
        on container: DIContainer = .shared,
        default defaultValue: Value? = nil
    ) {
        self.identifier = identifier ?? .by(type: Value.self)
        self.container = container
        self.defaultValue = defaultValue
    }

    /// 주입된 값 또는 기본값을 반환하거나, 단위 테스트에 한해 주입값을 재정의합니다.
    ///
    /// - Note: `DEBUG` 모드에서만 런타임에 의존성을 재정의할 수 있도록 허용됩니다.
    ///         이 기능은 오직 **단위 테스트에서 목(Mock) 객체를 주입하는 용도**로만 사용하시기 바랍니다.
    ///
    /// `DIContainer`를 통해 의존성을 조회하며, 조회에 실패한 경우 기본값(`default`)을 반환합니다.
    /// 만약 의존성도 없고 기본값도 설정되어 있지 않다면 앱이 크래시될 수 있습니다.
    ///
    /// - Warning: 런타임 중 실제 앱에서 의존성을 동적으로 변경하는 것은 매우 위험하며, 예기치 못한 동작을 유발할 수 있습니다.
    ///            테스트 목적이 아닌 코드에서 이 기능을 사용하는 것은 권장되지 않습니다.
    var wrappedValue: Value {
        get {
            (try? container.resolve(identifier)) ?? defaultValue!
        }
        set {
#if DEBUG
            container.register(identifier) { _ in newValue }
#endif
        }
    }
}

extension Injected {

    /// 주입된 DI 컨테이너를 테스트용으로 교체합니다.
    ///
    /// - Important: 이 메서드는 오직 단위 테스트를 위한 용도로만 사용하시기 바랍니다.
    ///
    /// - Parameter container: 새로운 테스트용 DI 컨테이너입니다.
    mutating func updateContainer(_ container: DIContainer) {
        self.container = container
    }
}
