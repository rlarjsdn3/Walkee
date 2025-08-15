//
//  PromptContext.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import Foundation

struct PromptContext {
    let date: Date = .now
    let userLocale: Locale = .current
    let user: UserDescriptor
    let health: HealthDescriptor
}

struct UserDescriptor {
    ///
    var age: Int
    ///
    var gender: String
    
    ///
    var obfuscatedAge: String {
        let decade = age / 10 * 10
        return "\(decade)대"
    }
}

struct HealthDescriptor {
    ///
    var weight: Double?
    ///
    var height: Double?
    ///
    var diseases: [Disease]?
    ///
    var stepCount: Double?
    ///
    var distanceWalkingRunning: Double?
    ///
    var activeEnergyBurned: Double?
    ///
    var basalEnergyBurned: Double?
    ///
    var walkingSpeed: Double?
    ///
    var stepLength: Double?
    ///
    var stepSpeed: Double?
    ///
    var walkingAsymmetryPercentage: Double?
    ///
    var doubleSupportPercentage: Double?
    ///
    var last7DaysStepCounts: [HKData]?
    ///
    var last12MonthsStepCounts: [HKData]?
    
    
    ///
    var obfuscatedWeight: String {
        guard let weight = weight else { return "정보 없음" }
        let decade = Int(weight / 10) * 10
        return "\(decade)kg대"
    }
    
    ///
    var obfuscatedHeight: String {
        guard let height = height else { return "정보 없음" }
        let decade = Int(height / 10) * 10
        return "\(decade)cm대"
    }

    ///
    var last7Days: String {
        last7DaysStepCounts?.map { "\($0.value)" }.joined(separator: " / ") ?? "정보 없음"
    }
    
    ///
    var last12Months: String {
        last12MonthsStepCounts?.map { "\($0.value)" }.joined(separator: " / ") ?? "정보 없음"
    }
}


