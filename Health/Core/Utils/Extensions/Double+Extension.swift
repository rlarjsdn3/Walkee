//
//  Double+Extension.swift
//  ProgessBarProject
//
//  Created by 김건우 on 8/2/25.
//

import Foundation

extension Double {

    /// 도(degree) 값을 라디안(radian) 값으로 변환합니다.
    var radian: Double {
        return self * .pi / 180
    }
}
