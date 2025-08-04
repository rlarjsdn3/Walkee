//
//  UIView+Extension.swift
//  ProgessBarProject
//
//  Created by 김건우 on 8/3/25.
//

import UIKit

extension UIView {
    
    /// 전달받은 여러 뷰를 현재 뷰의 서브뷰로 한 번에 추가합니다.
    ///
    /// - Parameter views: 현재 뷰에 추가할 서브뷰 목록입니다.
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
}
