//
//  NSObject+Nib.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

@MainActor
extension NSObject {

    /// 클래스와 동일한 이름을 가진 Nib 파일을 로드합니다.
    ///
    /// - Returns: 현재 클래스 이름을 기준으로 생성된 `UINib` 인스턴스를 반환합니다.
    ///            Nib 파일은 해당 클래스가 속한 번들에서 로드됩니다.
    static var nib: UINib {
        UINib(
            nibName: String(describing: Self.self),
            bundle: Bundle(for: Self.self)
        )
    }
}
