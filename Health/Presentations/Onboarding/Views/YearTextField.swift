//
//  YearTextField.swift
//  Health
//
//  Created by 권도현 on 8/27/25.
//

import UIKit

class YearTextField: UITextField {

    override var text: String? {
        didSet { invalidateIntrinsicContentSize() }
    }

    override var font: UIFont? {
        didSet { invalidateIntrinsicContentSize() }
    }

    override var intrinsicContentSize: CGSize {
        guard let text = self.text, let font = self.font else {
            return super.intrinsicContentSize
        }
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        let padding: CGFloat = 0
        let minWidth: CGFloat = 90
        let maxWidth: CGFloat = 110
        
        let finalWidth = min(max(textWidth + padding, minWidth), maxWidth)
        return CGSize(width: finalWidth, height: super.intrinsicContentSize.height)
    }
}
