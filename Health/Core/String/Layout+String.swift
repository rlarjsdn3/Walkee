//
//  Layout+String.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import Foundation

typealias LayoutString = String.Layout
extension String {

    struct Layout {

        /// 문자열을 표시할 때 사용할 기본 여백 값입니다.
        ///
        /// 일반적으로 텍스트 주변에 적용되는 좌우 마진 또는 패딩으로 사용되며,
        /// UI 디자인 가이드에 따라 기본값은 16pt로 설정되어 있습니다.
        static let defaultInset: CGFloat = 16.0
    }
}
