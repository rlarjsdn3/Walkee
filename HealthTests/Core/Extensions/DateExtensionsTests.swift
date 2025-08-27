//
//  DateExtensionsTests.swift
//  Health
//
//  Created by 권도현 on 8/27/25.
//

import XCTest
@testable import Health

final class DateExtensionsTests: XCTestCase {
    
    let calendar = Calendar.current
    
    func testYearMonthDayProperties() {
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 27))!
        XCTAssertEqual(date.year, 2025)
        XCTAssertEqual(date.month, 8)
        XCTAssertEqual(date.day, 27)
    }
    
    func testHourMinuteProperties() {
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 27, hour: 14, minute: 30))!
        XCTAssertEqual(date.hour, 14)
        XCTAssertEqual(date.minute, 30)
    }
    
    func testYesterday() {
        let today = calendar.startOfDay(for: Date())
        let yesterday = today.yesterday
        XCTAssertEqual(yesterday, calendar.date(byAdding: .day, value: -1, to: today))
    }
    
    func testStartOfDayEndOfDay() {
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 27, hour: 15))!
        let start = date.startOfDay()
        let end = date.endOfDay()
        XCTAssertEqual(calendar.component(.hour, from: start), 0)
        XCTAssertEqual(calendar.component(.minute, from: start), 0)
        XCTAssertEqual(calendar.component(.hour, from: end), 0)
        XCTAssertEqual(end > start, true)
    }
    
    func testRangeOfDay() {
        let date = Date()
        let range = date.rangeOfDay()
        XCTAssertEqual(range.startOfDay, date.startOfDay())
        XCTAssertEqual(range.endOfDay, date.endOfDay())
    }
    
    func testStartEndOfWeek() {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // UTC 기준
        
        let dateComponents = DateComponents(year: 2025, month: 8, day: 27) // 수요일
        let date = calendar.date(from: dateComponents)!
        
        guard let startOfWeek = date.startOfWeek(using: calendar),
              let endOfWeek = date.endOfWeek(using: calendar) else {
            XCTFail("startOfWeek 또는 endOfWeek 계산 실패")
            return
        }
        
        let startWeekday = calendar.component(.weekday, from: startOfWeek)
        let endWeekday = calendar.component(.weekday, from: endOfWeek)
        
        XCTAssertEqual(startWeekday, 2, "주 시작은 월요일이어야 함")
        XCTAssertEqual(endWeekday, 1, "주 끝은 일요일이어야 함")
        
        // 날짜 간격 확인 (7일)
        let dayDiff = calendar.dateComponents([.day], from: startOfWeek, to: endOfWeek).day
        XCTAssertEqual(dayDiff, 6, "startOfWeek ~ endOfWeek 간격은 6일이어야 함")
    }
    
    func testStartEndOfMonth() {
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        let start = date.startOfMonth()
        let end = date.endOfMonth()
        XCTAssertEqual(calendar.component(.day, from: start!), 1)
        XCTAssertEqual(calendar.component(.day, from: end!), 31)
    }
    
    func testDatesInMonth() {
        let date = calendar.date(from: DateComponents(year: 2025, month: 2, day: 10))!
        let dates = date.datesInMonth()
        XCTAssertEqual(dates.count, 28) // 윤년 체크 필요 시 추가 테스트
        XCTAssertEqual(calendar.component(.day, from: dates.first!), 1)
        XCTAssertEqual(calendar.component(.day, from: dates.last!), 28)
    }
    
    func testAddingDaysAndMonths() {
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 27))!
        let plusOneDay = date.addingDays(1)!
        let minusTwoDays = date.addingDays(-2)!
        XCTAssertEqual(calendar.component(.day, from: plusOneDay), 28)
        XCTAssertEqual(calendar.component(.day, from: minusTwoDays), 25)
        
        let plusOneMonth = date.addingMonths(1)!
        XCTAssertEqual(calendar.component(.month, from: plusOneMonth), 9)
    }
    
    func testIsEqualComponents() {
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 27, hour: 10))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 27, hour: 22))!
        XCTAssertTrue(date1.isEqual([.year, .month, .day], with: date2))
        XCTAssertFalse(date1.isEqual([.year, .month, .day, .hour], with: date2))
    }
    
    func testDayAndMonthDiff() {
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 1))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        XCTAssertEqual(date1.dayDiff(to: date2), 14)
        
        let date3 = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!
        XCTAssertEqual(date1.monthDiff(to: date3), 2)
    }
    
    func testNextDate() {
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 27))!
        let nextMonday = date.next(DateComponents(weekday: 2), direction: .forward)!
        XCTAssertEqual(calendar.component(.weekday, from: nextMonday), 2)
    }
}
