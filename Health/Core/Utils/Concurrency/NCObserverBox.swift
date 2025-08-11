//
//  NCObserverBox.swift
//  Health
//
//  Created by Nat Kim on 8/11/25.
//

import Foundation


/// NotificationCenter의 토큰은 Sendable이 아니기 때문에 @Sendable 클로저에서 안전하게 캡처하기 위함
final class NCObserverBox: @unchecked Sendable {
	let token: NSObjectProtocol
	init(_ token: NSObjectProtocol) { self.token = token }
}
