//
//  DynamicWidthTextField.swift
//  Health
//
//  Created by 권도현 on 8/25/25.
//


import UIKit

/// 사용자가 입력한 텍스트 길이에 따라 너비가 동적으로 변하는 `UITextField`.
///
/// `DynamicWidthTextField`는 텍스트의 길이에 맞춰 intrinsic content size를 조정하여
/// 입력값이 잘리지 않고 표시되도록 한다. 최소/최대 너비 범위를 설정하여 UI 레이아웃의 안정성을 유지한다.
class DynamicWidthTextField: UITextField {

    /// 텍스트 값이 변경될 때마다 intrinsic content size를 무효화하여 레이아웃을 다시 계산한다.
    override var text: String? {
        didSet { invalidateIntrinsicContentSize() }
    }

    /// 폰트가 변경될 때마다 intrinsic content size를 무효화한다.
    override var font: UIFont? {
        didSet { invalidateIntrinsicContentSize() }
    }

    /// 텍스트 길이와 폰트 크기에 기반해 동적으로 계산된 intrinsic content size를 반환한다.
    ///
    /// - 계산 방식:
    ///   - `NSString.size(withAttributes:)`를 사용해 텍스트의 실제 렌더링 너비를 측정한다.
    ///   - 최소/최대 너비를 적용하여 UI가 깨지지 않도록 제한한다.
    /// - Returns: 텍스트 필드의 적절한 크기(`CGSize`)
    override var intrinsicContentSize: CGSize {
        guard let text = self.text, let font = self.font else {
            return super.intrinsicContentSize
        }
        
        // 텍스트의 실제 폭 계산
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        
        // 최소 및 최대 폭 제한
        let padding: CGFloat = 0
        let minWidth: CGFloat = 70
        let maxWidth: CGFloat = 100
        
        let finalWidth = min(max(textWidth + padding, minWidth), maxWidth)
        return CGSize(width: finalWidth, height: super.intrinsicContentSize.height)
    }
}
