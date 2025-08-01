//
//  Date+Formatter.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import Foundation

extension Date {

    /// 날짜 형식 지정을 위한 포맷 열거형입니다.
    enum Formatter: String {
        /// 요일 전체 (예: "월요일")
        case weekday = "EEEE"
        /// 요일 축약형 (예: "월")
        case weekdayShortand = "EEE"
        /// 월일 형식 (예: "8월 1일")
        case md = "M월 d일"
    }

    /// 지정된 포맷 스타일을 사용해 현재 날짜를 문자열로 변환합니다.
    ///
    /// 내부적으로 `Formatter` 열거형의 `rawValue`를 활용하여 날짜를 형식화합니다.
    ///
    /// - Parameter style: 사용할 날짜 포맷 스타일입니다.
    /// - Returns: 지정된 형식으로 변환된 날짜 문자열입니다.
    func formatted(using style: Date.Formatter) -> String {
        formatted(using: style.rawValue)
    }

    /// 지정된 포맷 문자열을 사용해 현재 날짜를 문자열로 변환합니다.
    ///
    /// `DateFormatter`를 이용해 로컬(`ko_KR`) 및 현재 시간대 기준으로 형식화된 문자열을 반환합니다.
    ///
    /// - Parameter string: `DateFormatter`에 사용할 날짜 형식 문자열입니다.
    /// - Returns: 지정된 형식으로 변환된 날짜 문자열입니다.
    func formatted(using string: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "ko_kr")
        dateFormatter.dateFormat = string
        return dateFormatter.string(from: self)
    }
}
