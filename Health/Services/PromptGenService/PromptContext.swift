//
//  PromptContext.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import Foundation
struct PromptContext {
    /// 프롬프트 생성 기준 날짜
    let date: Date = .now
    /// 사용자 로케일 정보
    let userLocale: Locale = .current
    /// 사용자 및 건강 데이터 디스크립터
    let descriptor: PromptDescriptor
}

struct PromptDescriptor {
    /// 사용자 나이
    var age: Int
    /// 사용자 성별
    var gender: String
    /// 사용자 체중(kg)
    var weight: Double?
    /// 사용자 신장(cm)
    var height: Double?
    /// 사용자 질병 목록
    var diseases: [Disease]?
    /// 목표 걸음 수
    var goalStepCount: Int
    /// 금일 걸음 수
    var stepCount: Double?
    /// 금일 걸은 거리(km)
    var distanceWalkingRunning: Double?
    /// 금일 활동 에너지(kcal)
    var activeEnergyBurned: Double?
    /// 금일 휴식 에너지(kcal)
    var basalEnergyBurned: Double?
    /// 보행 보폭(cm)
    var stepLength: Double?
    /// 보행 속도(m/s)
    var stepSpeed: Double?
    /// 보행 비대칭성 비율(0~1)
    var walkingAsymmetryPercentage: Double?
    /// 이중 지지 시간 비율(0~1)
    var doubleSupportPercentage: Double?
    /// 최근 1개월간 걸음 수 데이터
    var this1MonthStepCounts: [HKData]?

    /// 나이를 10단위로 비식별화한 문자열
    var obfuscatedAge: String {
        let decade = age / 10 * 10
        return "\(decade)대"
    }

    /// 체중을 10단위로 비식별화한 문자열
    var obfuscatedWeight: String {
        guard let weight = weight else { return "정보 없음" }
        let decade = Int(weight / 10) * 10
        return "\(decade)kg대"
    }

    /// 신장을 10단위로 비식별화한 문자열
    var obfuscatedHeight: String {
        guard let height = height else { return "정보 없음" }
        let decade = Int(height / 10) * 10
        return "\(decade)cm대"
    }

    /// 최근 1개월간 걸음 수를 "/"로 구분한 문자열
    var this1Months: String {
        this1MonthStepCounts?.map { "\($0.value)" }.joined(separator: " / ") ?? "정보 없음"
    }
}
