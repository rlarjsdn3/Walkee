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

extension UIView {

    /// 뷰에 블러(흐림) 효과를 추가합니다.
    ///
    /// - Parameter style: 적용할 블러 효과의 스타일입니다.
    ///
    /// 지정한 스타일로 `UIVisualEffectView`를 생성하여 현재 뷰의
    /// 맨 아래 서브뷰로 추가합니다. 블러 뷰의 크기는 현재 뷰의
    /// `bounds`에 맞추고, 뷰 크기 변경 시 자동으로 조정되도록
    /// `autoresizingMask`를 설정합니다.
    func addBlurEffect(_ style: UIBlurEffect.Style) {
        let effect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
    }
}
