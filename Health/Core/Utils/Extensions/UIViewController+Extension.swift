//
//  UIViewController+Extension.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import UIKit

extension UIViewController {
    
    /// 지정한 자식 뷰 컨트롤러를 현재 뷰 컨트롤러에 추가하고, 주어진 컨테이너 뷰에 해당 자식의 뷰를 삽입합니다.
    ///
    /// 이 메서드는 `addChild(_:)`, `didMove(toParent:)`, 뷰 계층 추가 등의 작업을 일괄 수행하여
    /// 자식 뷰 컨트롤러를 안전하게 부모 컨텍스트에 연결합니다.
    ///
    /// - Parameters:
    ///   - vc: 추가할 자식 `UIViewController`입니다.
    ///   - container: 자식 뷰 컨트롤러의 뷰를 삽입할 대상 `UIView`입니다.
    func addChild(_ vc: UIViewController, to container: UIView) {
        self.addChild(vc)
        container.addSubview(vc.view)
        vc.view.frame = container.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.didMove(toParent: self)
    }
    
    /// 현재 뷰 컨트롤러로부터 지정한 자식 뷰 컨트롤러를 제거합니다.
    ///
    /// 이 메서드는 `willMove(toParent:)`, 뷰 제거, `removeFromParent()` 호출을 포함하여
    /// 자식 뷰 컨트롤러를 안전하게 뷰 계층과 부모 컨텍스트에서 분리합니다.
    ///
    /// - Parameter vc: 제거할 자식 `UIViewController`입니다.
    func removeChild(_ vc: UIViewController) {
        self.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
    }
}
