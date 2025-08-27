//
//  Array+Extension.swift
//  BarChartViewProject
//
//  Created by 김건우 on 8/2/25.
//

import Foundation

extension Array {

    /// 지정한 인덱스가 배열 범위를 벗어나지 않는 경우 해당 요소를 반환합니다.
    ///
    /// 잘못된 인덱스로 접근할 경우 앱이 크래시나는 것을 방지하며,
    /// 유효하지 않은 인덱스일 경우 `nil`을 반환합니다.
    ///
    /// - Parameter index: 접근하려는 배열 인덱스입니다.
    /// - Returns: 해당 인덱스의 요소 또는 유효하지 않은 경우 `nil`
    subscript(safe index: Array.Index) -> Element? {
        guard 0 <= index && index < count else { return nil }
        return self[index]
    }
}
