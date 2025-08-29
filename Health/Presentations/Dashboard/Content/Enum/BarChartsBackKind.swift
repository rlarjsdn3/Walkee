//
//  BarChartsBackKind.swift
//  Health
//
//  Created by 김건우 on 8/12/25.
//

import Foundation

enum BarChartsBackKind {
    /// 기준 시점부터 n일 전까지 포함
    case daysBack(Int)
    /// 기준 시점부터 n개월 전까지 포함
    case monthsBack(Int)

    var count: Int {
        switch self {
        case let .daysBack(value), let .monthsBack(value):
            return max(0, abs(value))
        }
    }

    var interval: DateComponents {
        switch self {
        case .daysBack:     return DateComponents(day: 1)
        case .monthsBack:   return DateComponents(month: 1)
        }
    }

    var component: Calendar.Component {
        switch self {
        case .daysBack:     return .day
        case .monthsBack:   return .month
        }
    }

    func startDate(_ anchorDate: Date) -> Date? {
        switch self {
        case .daysBack(let int):
            return anchorDate.startOfDay().addingDays(-int+1)
        case .monthsBack(let int):
            return anchorDate.startOfMonth()?.addingMonths(-int+1)
        }
    }

    func endDate(_ anchorDate: Date) -> Date? {
        switch self {
        case .daysBack:
            return anchorDate.endOfDay()
        case .monthsBack:
            return anchorDate.endOfMonth()
        }
    }
}

extension BarChartsBackKind: Hashable {
}
