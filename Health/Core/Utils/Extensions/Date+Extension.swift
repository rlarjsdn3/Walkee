//
//  Date+Extension.swift
//  HealthKitService
//
//  Created by 김건우 on 8/4/25.
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

    // 하루 전 날짜를 반환합니다.
    var yesterday: Date {
        calendar.date(byAdding: .day, value: -1, to: self)!
    }
}


extension Date {
    
    /// 해당 날짜의 시작 시각과 종료 시각을 반환합니다.
    ///
    /// - Parameter calendar: 기준이 되는 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 시작 시각과 종료 시각으로 구성된 튜플입니다.
    func rangeOfDay(using calendar: Calendar = .current) -> (startOfDay: Date, endOfDay: Date) {
        (startOfDay(using: calendar), endOfDay(using: calendar))
    }

    /// 해당 날짜의 시작 시각을 반환합니다.
    ///
    /// - Parameter calendar: 기준이 되는 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 시작 시각을 나타내는 `Date` 값입니다.
    func startOfDay(using calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }

    /// 해당 날짜의 종료 시각을 반환합니다.
    ///
    /// - Parameter calendar: 기준이 되는 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 종료 시각을 나타내는 `Date` 값입니다.
    func endOfDay(using calendar: Calendar = .current) -> Date {
        startOfDay(using: calendar).addingTimeInterval(.dayInterval)
    }

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
        let components = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)
    }

    /// 해당 날짜가 속한 주의 마지막 날짜(보통 일요일)를 반환합니다.
    ///
    /// - Parameter calendar: 사용할 캘린더입니다. 기본값은 `.current`입니다.
    /// - Returns: 주의 마지막 날짜입니다.
    func endOfWeek(using calendar: Calendar = .current) -> Date? {
        guard let startOfWeek = self.startOfWeek(using: calendar) else { return nil }
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek)
    }

    /// 해당 날짜가 속한 달의 시작일과 종료일을 반환합니다.
    ///
    /// 예: 2025년 8월 5일 → (2025년 8월 1일, 2025년 8월 31일)
    ///
    /// - Parameter calendar: 기준이 되는 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 시작일과 종료일로 구성된 튜플입니다. 계산에 실패한 경우 nil을 반환할 수 있습니다.
    func rangeOfMonth(using calendar: Calendar = .current) -> (Date?, Date?) {
        return (startOfMonth(using: calendar), endOfMonth(using: calendar))
    }

    /// 해당 날짜가 속한 달의 첫 번째 날짜를 반환합니다.
    ///
    /// 예: 2025년 8월 5일 → 2025년 8월 1일
    ///
    /// - Parameter calendar: 기준이 되는 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 해당 월의 시작일입니다. 계산에 실패한 경우 nil을 반환할 수 있습니다.
    func startOfMonth(using calendar: Calendar = .current) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)
    }

    /// 해당 날짜가 속한 달의 마지막 날짜를 반환합니다.
    ///
    /// 예: 2025년 8월 5일 → 2025년 8월 31일
    ///
    /// - Parameter calendar: 기준이 되는 캘린더입니다. 기본값은 현재 캘린더입니다.
    /// - Returns: 해당 월의 종료일입니다. 계산에 실패한 경우 nil을 반환할 수 있습니다.
    func endOfMonth(using calendar: Calendar = .current) -> Date? {
        let components = DateComponents(month: 1, day: -1)
        guard let startOfMonth = self.startOfMonth(using: calendar) else { return nil }
        return calendar.date(byAdding: components, to: startOfMonth)
    }

    /// 해당 월의 모든 날짜 배열을 반환합니다.
    func datesInMonth(using calendar: Calendar = .current) -> [Date] {
        guard let start = self.startOfMonth(using: calendar),
              let end = self.endOfMonth(using: calendar) else {
            return []
        }

        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }
}

extension Date {
    
    /// 현재 날짜에서 지정한 일 수를 더하거나 뺀 새로운 날짜를 반환합니다.
    ///
    /// - Parameter days: 더하거나 뺄 일 수입니다. 양수면 미래 날짜, 음수면 과거 날짜를 반환합니다.
    /// - Returns: 계산된 새로운 `Date` 객체. 계산이 불가능한 경우 `nil`을 반환합니다.
    func addingDays(_ days: Int) -> Date? {
        calendar.date(byAdding: .day, value: days, to: self)
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

    /// 지정된 구성 요소에 일치하는 다음 날짜를 반환합니다.
    ///
    /// 예를 들어, 매주 월요일 또는 매월 1일 등 특정 요일 또는 날짜를 기준으로 다음 시점을 계산할 때 사용할 수 있습니다.
    ///
    /// - Parameters:
    ///   - components: 일치시킬 날짜 구성 요소입니다.
    ///   - direction: 검색 방향입니다. 기본값은 `.backward`이며, `.forward`로 지정 시 미래 날짜를 검색합니다.
    /// - Returns: 구성 요소와 일치하는 다음 날짜. 계산에 실패한 경우 nil을 반환할 수 있습니다.
    func next(
        _ components: DateComponents,
        direciton: Calendar.SearchDirection = .backward
    ) -> Date? {
        calendar.nextDate(
            after: self,
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: direciton
        )
    }
}

fileprivate extension Date {

    var calendar: Calendar {
        Calendar.current
    }
}

fileprivate extension TimeInterval {

    static var dayInterval: TimeInterval {
        86_400
    }
}
