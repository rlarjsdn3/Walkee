//
//  NCObserverBox.swift
//  Health
//
//  Created by Seohyun Kim on 8/11/25.
//

import Foundation

/// `NotificationCenter` 옵저버 토큰을 안전하게 캡처하기 위한 래퍼.
///
///   - `NSObjectProtocol`(옵저버 토큰)은 `Sendable`이 아님.
///   - 비동기 컨텍스트나 `@Sendable` 클로저에서 캡처 시 경고가 발생.
///   - 이 래퍼로 감싸 `@unchecked Sendable`로 취급해 경고를 억제.
/// - 주의:
///   - `@unchecked Sendable`은 개발자가 스레드 안전을 보증한다는 의미.
///   - 실제 제거(`removeObserver`)는 동일 스레드/액터에서 일관되게 수행할 것.
///
/// ## 사용 예
/// ```swift
/// let token = NotificationCenter.default.addObserver( ... )
/// let boxed = NCObserverBox(token) // @Sendable 클로저에서도 안전하게 캡처
/// ```
final class NCObserverBox: @unchecked Sendable {
	/// 등록된 옵저버 토큰
	let token: NSObjectProtocol
	/// 옵저버 토큰을 래핑
	/// - Parameter token: `NotificationCenter.addObserver`가 반환한 토큰
	init(_ token: NSObjectProtocol) { self.token = token }
}
