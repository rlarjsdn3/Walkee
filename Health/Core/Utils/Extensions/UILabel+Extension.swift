//
//  UILabel+Extension.swift
//  Health
//
//  Created by 하재준 on 8/19/25.
//

import UIKit

extension UILabel {
    
    /// Profile에서 Bottom Sheet 띄울때 Title Label 지정하기 위한 메서드
    ///
    ///
    func configureAsTitle(_ title: String) {
        self.text = title
        self.textColor = .label
        self.font = .preferredFont(forTextStyle: .title2)
        self.textAlignment = .center
        self.adjustsFontForContentSizeCategory = true
    }
}
