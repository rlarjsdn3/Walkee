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

extension UIView {
    
    
    /// 현재 뷰 컨트롤러의 세로/가로 Size Class 조합에 따라 해당 클로저를 실행해 값을 반환합니다.
    ///
    /// - Parameters:
    ///   - vChC: 세로 Compact / 가로 Compact 일 때 실행할 클로저
    ///   - vChR: 세로 Compact / 가로 Regular 일 때 실행할 클로저
    ///   - vRhC: 세로 Regular / 가로 Compact 일 때 실행할 클로저
    ///   - vRhR: 세로 Regular / 가로 Regular 일 때 실행할 클로저
    /// - Returns: 매칭되는 클로저의 반환값. 매칭되는 클로저가 없으면 `nil`
    @discardableResult
    func sizeClasses<Value>(
        vChC: (() -> Value)? = nil,
        vChR: (() -> Value)? = nil,
        vRhC: (() -> Value)? = nil,
        vRhR: (() -> Value)? = nil
    ) -> Value? {
        let h: UIUserInterfaceSizeClass = {
            switch traitCollection.horizontalSizeClass {
            case .regular: return .regular
            case .compact, .unspecified: return .compact
            @unknown default: return .compact
            }
        }()
        
        let v: UIUserInterfaceSizeClass = {
            switch traitCollection.verticalSizeClass {
            case .regular: return .regular
            case .compact, .unspecified: return .compact
            @unknown default: return .compact
            }
        }()
        
        switch (v, h) {
        case (.compact, .compact): return vChC?()
        case (.compact, .regular): return vChR?()
        case (.regular, .compact): return vRhC?()
        case (.regular, .regular): return vRhR?()
        default: return nil
        }
    }
}

extension UIView {

    /// 현재 뷰의 응답자 체인을 따라 올라가며 가장 먼저 찾은 뷰 컨트롤러를 반환합니다.
    /// - Returns: 뷰와 연결된 첫 번째 `UIViewController` 또는 없을 경우 `nil`
    var firstAvailableViewController: UIViewController? {
        var next: UIResponder? = self.next
        while let responder = next {
            if let vc = responder as? UIViewController {
                return vc
            }
            next = responder.next
        }
        return nil
    }
}
