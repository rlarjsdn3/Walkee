//
//  YearTextField.swift
//  Health
//
//  Created by 권도현 on 8/27/25.
//

import UIKit

/// 연도 입력을 위한 사용자 정의 `UITextField`
///
/// - 입력된 텍스트 길이에 따라 `intrinsicContentSize`가 동적으로 조정된다.
/// - 주로 출생년도나 특정 연도를 입력받을 때 사용된다.
/// - 최소/최대 너비를 지정하여 UI가 깨지지 않도록 보장한다.
class YearTextField: UITextField {

    /// 텍스트가 변경될 때마다 intrinsic size를 무효화하여 레이아웃을 새로 계산
    override var text: String? {
        didSet { invalidateIntrinsicContentSize() }
    }

    /// 폰트가 변경될 때마다 intrinsic size를 무효화하여 레이아웃을 새로 계산
    override var font: UIFont? {
        didSet { invalidateIntrinsicContentSize() }
    }

    /// 텍스트 길이에 따라 동적으로 크기를 조정하는 intrinsic size
    ///
    /// - 최소 너비: 90pt
    /// - 최대 너비: 110pt
    /// - 텍스트 + 패딩 크기를 계산하여 그 사이 값으로 설정
    override var intrinsicContentSize: CGSize {
        guard let text = self.text, let font = self.font else {
            return super.intrinsicContentSize
        }
        
        // 텍스트의 실제 가로 길이 계산
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        
        // 패딩 및 최소/최대 값 적용
        let padding: CGFloat = 0
        let minWidth: CGFloat = 90
        let maxWidth: CGFloat = 110
        let finalWidth = min(max(textWidth + padding, minWidth), maxWidth)
        
        return CGSize(width: finalWidth, height: super.intrinsicContentSize.height)
    }
}

