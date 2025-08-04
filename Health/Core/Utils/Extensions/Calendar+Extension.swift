//
//  Calendar+Extension.swift
//  Health
//
//  Created by 김건우 on 8/4/25.
//

import Foundation

extension Calendar {

    /// 그레고리력(Gregorian calendar) 기반 캘린더를 반환합니다.
    static var gregorian: Calendar {
        Calendar(identifier: .gregorian)
    }
}
