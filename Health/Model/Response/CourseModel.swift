//
//  CourseModel.swift
//  Health
//
//  Created by juks86 on 8/9/25.
//

import Foundation

//  필요한 정보만 포함한 간소화된 모델
struct WalkingCourse: Codable, Hashable {
    let crsKorNm: String      // 코스명 (해파랑길 6코스)
    let crsDstnc: String      // 거리 (16km)
    let crsLevel: String      // 난이도 (1:하/2:중/3:상)
    let sigun: String         // 지역 (울산 남구)
    let gpxpath: String       // GPX 파일 경로
    let crsTotlRqrmHour: String //총 소요 시간
}

// API 응답용 래퍼 (전체 구조는 유지하되 필요한 부분만 파싱)
struct WalkingCourseResponse: Codable {
    let response: WalkingCourseBody
}

struct WalkingCourseBody: Codable {
    let header: ResponseHeader
    let body: WalkingCourseItems
}

struct ResponseHeader: Codable {
    let resultCode: String
    let resultMsg: String
}

struct WalkingCourseItems: Codable {
    let items: WalkingCourseList
    let numOfRows: Int
    let pageNo: Int
    let totalCount: Int
}

struct WalkingCourseList: Codable {
    let item: [WalkingCourse]
}
