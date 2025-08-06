//
//  UIViewController+Extension.swift
//  Health
//
//  Created by 김건우 on 8/6/25.
//

import UIKit

extension UIViewController {
    
    /// <#Description#>
    /// - Parameters:
    ///   - vc: <#vc description#>
    ///   - container: <#container description#>
    func addChild(_ vc: UIViewController, to container: UIView) {
        self.addChild(vc)
        self.view.addSubview(vc.view)
        vc.view.frame = container.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.didMove(toParent: self)
    }
    
    /// <#Description#>
    /// - Parameter vc: <#vc description#>
    func removeChild(_ vc: UIViewController) {
        self.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
    }
}
