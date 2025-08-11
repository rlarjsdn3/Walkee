//
//  KeyboardEvents.swift
//  Health
//
//  Created by Nat Kim on 8/11/25.
//
import UIKit
import Foundation

struct KeyboardChangePayload: Sendable {
	let duration: Double
	let curveRaw: UInt
	let endX: Double
	let endY: Double
	let endW: Double
	let endH: Double
	
	init(duration: Double, curveRaw: UInt, endFrame: CGRect) {
		self.duration = duration
		self.curveRaw = curveRaw
		self.endX = Double(endFrame.origin.x)
		self.endY = Double(endFrame.origin.y)
		self.endW = Double(endFrame.size.width)
		self.endH = Double(endFrame.size.height)
	}
	
	/// UIKit 좌표계로 복원 (메인 액터에서 사용)
	func endCGRect() -> CGRect {
		CGRect(x: endX, y: endY, width: endW, height: endH)
	}
}

/// NotificationCenter > AsyncStream<KeyboardChangePayload>
/// -  Notification(Non-Sendable)을 밖으로 내보내지 않고,
///         Sendable인 Payload만 흘려보낸다.
enum KeyboardEvents {
	/// keyboardWillChangeFrame 스트림 (메인 큐 수신)
	static func willChangeFrameStream() -> AsyncStream<KeyboardChangePayload> {
		AsyncStream { continuation in
			let token = NotificationCenter.default.addObserver(
				forName: UIResponder.keyboardWillChangeFrameNotification,
				object: nil,
				queue: .main
			) { noti in
				
				guard let info = noti.userInfo,
					  let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
					  let curve   = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
					  let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
				else { return }
				
				continuation.yield(KeyboardChangePayload(
					duration: duration,
					curveRaw: curve,
					endFrame: endFrame
				))
			}
			
			// non-Sendable 캡처 회피: 박스 캡처 + 메인에서 해제
			let box = NCObserverBox(token)
			continuation.onTermination = { @Sendable _ in
				Task { @MainActor in
					NotificationCenter.default.removeObserver(box.token)
				}
			}
		}
	}
}
