//
//  KeyboardEvents.swift
//  Health
//
//  Created by Seohyun Kim on 8/11/25.
//
import UIKit
/// 시스템 키보드 관련 이벤트를 `AsyncStream` 으로 제공하는 유틸리티.
/// - 역할: `NotificationCenter` 기반 키보드 프레임 변경 이벤트를 비동기 스트림 형태로 래핑.
/// - Note: `KeyboardObserver` 와 함께 사용해 `UIInset` 조정, 스크롤 동작 등을 단순화.
enum KeyboardEvents {
	/// 키보드 frame 변경 이벤트를 스트림으로 노출
	/// - Returns: `AsyncStream<KeyboardChangePayload>` 비동기 시퀀스
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
/// 키보드 프레임 변경 이벤트에 담길 데이터 구조
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

