//
//  UIStackView+Extension.swift
//  ProgessBarProject
//
//  Created by 김건우 on 8/3/25.
//

import UIKit

extension UIStackView {
    
    /// 전달받은 여러 뷰를 스택 뷰의 정렬된 서브뷰(arrangedSubviews)로 한 번에 추가합니다.
    ///
    /// - Parameter views: 스택 뷰에 추가할 정렬된 서브뷰 목록입니다.
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach { addArrangedSubview($0) }
    }
}
