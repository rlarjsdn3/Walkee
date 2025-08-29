//
//  UITextField+Padding.swift
//  Health
//
//  Created by Seohyun Kim on 8/28/25.
//

import UIKit

extension UITextField {
	/// 커서/텍스트/플레이스홀더 모두에 동일 패딩 적용
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
