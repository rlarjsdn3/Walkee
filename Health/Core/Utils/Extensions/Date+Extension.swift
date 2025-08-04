//
//  Date+Extenson.swift
//  BarChartViewProject
//
//  Created by 김건우 on 8/3/25.
//

import Foundation

extension Date {

    /// 현재 날짜의 연도 값을 반환합니다.
    var year: Int {
        calendar.component(.year, from: self)
    }

    /// 현재 날짜의 월 값을 반환합니다.
    var month: Int {
        calendar.component(.month, from: self)
    }

    /// 현재 날짜의 일 값을 반환합니다.
    var day: Int {
        calendar.component(.day, from: self)
    }

    /// 현재 날짜의 시(hour) 값을 반환합니다. (24시간 기준)
    var hour: Int {
        calendar.component(.hour, from: self)
    }

    /// 현재 날짜의 분(minute) 값을 반환합니다.
    var minute: Int {
        calendar.component(.minute, from: self)
    }
}

extension Date {

    /// 해당 날짜가 속한 주의 시작 날짜와 종료 날짜를 반환합니다.
    ///
    /// 내부적으로 `startOfWeek`와 `endOfWeek`를 호출하여 한 주의 범위를 계산합니다.
    ///
    /// - Parameter calendar: 사용할 캘린더입니다. 기본값은 `.current`입니다.
    /// - Returns: 시작일과 종료일로 구성된 튜플입니다.
    func rangeOfWeek(using calendar: Calendar = .current) -> (startOfWeek: Date?, endOfWeek: Date?) {
        return (startOfWeek(using: calendar), endOfWeek(using: calendar))
    }

    /// 해당 날짜가 속한 주의 시작 날짜(보통 월요일)를 반환합니다.
    ///
    /// ISO 8601 기준을 따르며, 주의 첫 날은 일반적으로 월요일입니다.
    ///
    /// - Parameter calendar: 사용할 캘린더입니다. 기본값은 `.current`입니다.
    /// - Returns: 주의 시작 날짜입니다.
    func startOfWeek(using calendar: Calendar = .current) -> Date? {
        return calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date
    }

    /// 해당 날짜가 속한 주의 마지막 날짜(보통 일요일)를 반환합니다.
    ///
    /// - Parameter calendar: 사용할 캘린더입니다. 기본값은 `.current`입니다.
    /// - Returns: 주의 마지막 날짜입니다.
    func endOfWeek(using calendar: Calendar = .current) -> Date? {
        guard let startOfWeek = self.startOfWeek(using: calendar) else { return nil }
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek)
    }
    
    /// 해당 날짜가 속한 월의 시작일과 종료일을 반환합니다.
    ///
    /// - Parameter calendar: 계산에 사용할 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 시작일과 종료일을 튜플로 반환하며, 계산이 불가능한 경우 nil이 포함될 수 있습니다.
    func rangeOfMonth(using calendar: Calendar = .current) -> (Date?, Date?) {
        return (startOfMonth(using: calendar), endOfMonth(using: calendar))
    }

    /// 해당 날짜가 속한 월의 시작일을 반환합니다.
    ///
    /// - Parameter calendar: 계산에 사용할 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 월의 시작일을 나타내는 `Date` 객체이며, 계산이 불가능한 경우 nil을 반환합니다.
    func startOfMonth(using calendar: Calendar = .current) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)
    }

    /// 해당 날짜가 속한 월의 종료일을 반환합니다.
    ///
    /// - Parameter calendar: 계산에 사용할 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 월의 마지막 날짜를 나타내는 `Date` 객체이며, 계산이 불가능한 경우 nil을 반환합니다.
    func endOfMonth(using calendar: Calendar = .current) -> Date? {
        let components = DateComponents(month: 1, day: -1)
        guard let startOfMonth = self.startOfMonth(using: calendar) else { return nil }
        return calendar.date(byAdding: components, to: startOfMonth)
    }
}

extension Date {

    /// 주어진 날짜와 특정 캘린더 컴포넌트 단위로 값이 동일한지 비교합니다.
    ///
    /// 예를 들어 `.year`, `.month`, `.day` 등의 컴포넌트를 전달하면,
    /// 두 날짜가 해당 항목들에 대해 같은 값을 갖는지 확인합니다.
    ///
    /// - Parameters:
    ///   - components: 비교할 캘린더 컴포넌트 집합입니다.
    ///   - date: 비교 대상 날짜입니다.
    /// - Returns: 지정된 컴포넌트 기준으로 두 날짜가 동일하면 `true`, 그렇지 않으면 `false`입니다.
    func isEqual(_ components: Set<Calendar.Component>, with date: Date) -> Bool {
        for component in components {
            let target = calendar.component(component, from: date)
            if calendar.component(component, from: self) != target {
                return false
            }
        }
        return true
    }
}

fileprivate extension Date {

    var calendar: Calendar {
        Calendar.current
    }
}
