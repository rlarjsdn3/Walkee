//
//  NSLayoutConstraint+Extension.swift
//  Health
//
//  Created by 김건우 on 8/25/25.
//

import UIKit

extension NSLayoutConstraint {
    
    /// <#Description#>
    /// - Parameter multiplier: <#multiplier description#>
    /// - Returns: <#description#>
    func setMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint.deactivate([self])

        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant
        )

        newConstraint.priority = priority
        newConstraint.shouldBeArchived = shouldBeArchived
        newConstraint.identifier = identifier

        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}
