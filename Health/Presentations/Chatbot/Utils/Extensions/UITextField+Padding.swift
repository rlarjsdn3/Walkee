//
//  UITextField+Padding.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit
/// `UITextField`에 좌/우 패딩 뷰를 간단히 붙이기 위한 유틸.
extension UITextField {
	/// 커서/텍스트/플레이스홀더 모두에 동일 패딩 적용
	///
	/// - Parameters:
	///   - left: 왼쪽 패딩 폭(포인트). 기본 0
	///   - right: 오른쪽 패딩 폭(포인트). 기본 0
	///
	/// - Note:
	///   - 내부적으로 `leftView`/`rightView`를 생성해 항상 표시.
	///   - 오토레이아웃 간섭 없이 단순 프레임으로 폭만 지정.
	///
	/// ## 사용 예
	/// ```swift
	/// textField.setPadding(left: 12, right: 8)
	/// ```
	func setPadding(left: CGFloat = 0, right: CGFloat = 0) {
		if left > 0 {
			let v = UIView(frame: CGRect(x: 0, y: 0, width: left, height: 1))
			v.isUserInteractionEnabled = false
			leftView = v
			leftViewMode = .always
		}
		if right > 0 {
			let v = UIView(frame: CGRect(x: 0, y: 0, width: right, height: 1))
			v.isUserInteractionEnabled = false
			rightView = v
			rightViewMode = .always
		}
	}
}
