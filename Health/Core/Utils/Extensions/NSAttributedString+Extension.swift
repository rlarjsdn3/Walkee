//
//  NSAttributedString+Extension.swift
//  ProgessBarProject
//
//  Created by 김건우 on 8/3/25.
//

import UIKit

extension NSAttributedString {

    /// 지정한 부분 문자열에 새로운 폰트를 적용한 `NSAttributedString`을 반환합니다.
    ///
    /// - Parameters:
    ///   - font: 적용할 폰트입니다.
    ///   - substring: 스타일을 적용할 대상 문자열입니다.
    /// - Returns: 해당 부분에 폰트가 적용된 새로운 `NSAttributedString`입니다.
    func font(
        _ font: UIFont,
        to substring: any StringProtocol
    ) -> NSAttributedString {
        guard let range = string.range(of: substring) else { return self }
        return self.font(font, range: range)
    }

    /// 지정한 문자열 범위에 새로운 폰트를 적용한 `NSAttributedString`을 반환합니다.
    ///
    /// - Parameters:
    ///   - font: 적용할 폰트입니다.
    ///   - range: 폰트를 적용할 문자열 범위입니다.
    /// - Returns: 해당 범위에 폰트가 적용된 새로운 `NSAttributedString`입니다.
    func font(
        _ font: UIFont,
        range: any RangeExpression<String.Index>
    ) -> NSAttributedString {
        let nsRange = NSRange(range, in: string)
        return applyingAttribute(.font, value: font, range: nsRange)
    }

    /// 지정한 부분 문자열에 전경색(foreground color)을 적용한 `NSAttributedString`을 반환합니다.
    ///
    /// - Parameters:
    ///   - foregroundColor: 적용할 전경색입니다.
    ///   - substring: 스타일을 적용할 대상 문자열입니다.
    /// - Returns: 해당 부분에 색상이 적용된 새로운 `NSAttributedString`입니다.
    func foregroundColor(
        _ foregroundColor: UIColor,
        to substring: any StringProtocol
    ) -> NSAttributedString {
        guard let range = string.range(of: substring) else { return self }
        return self.foregroundColor(foregroundColor, range: range)
    }

    /// 지정한 문자열 범위에 전경색(foreground color)을 적용한 `NSAttributedString`을 반환합니다.
    ///
    /// - Parameters:
    ///   - foregroundColor: 적용할 전경색입니다.
    ///   - range: 색상을 적용할 문자열 범위입니다.
    /// - Returns: 해당 범위에 색상이 적용된 새로운 `NSAttributedString`입니다.
    func foregroundColor(
        _ foregroundColor: UIColor,
        range: any RangeExpression<String.Index>
    ) -> NSAttributedString {
        let nsRange = NSRange(range, in: string)
        return applyingAttribute(.foregroundColor, value: foregroundColor, range: nsRange)
    }
}

extension NSAttributedString {

    /// 지정한 범위에 원하는 속성을 적용한 `NSAttributedString`을 반환합니다.
    ///
    /// - Parameters:
    ///   - name: 적용할 속성 키입니다. 예: `.font`, `.foregroundColor` 등.
    ///   - value: 속성에 적용할 값입니다.
    ///   - range: 속성을 적용할 NSRange 범위입니다. 기본값은 전체 범위입니다.
    /// - Returns: 속성이 적용된 새로운 `NSAttributedString`입니다.
    func applyingAttribute(
        _ name: NSAttributedString.Key,
        value: Any,
        range: NSRange? = nil
    ) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        let targetRange = range ?? NSRange(location: 0, length: length)
        mutableString.addAttribute(name, value: value, range: targetRange)
        return mutableString
    }
}
