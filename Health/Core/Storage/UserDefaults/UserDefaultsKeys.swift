//
//  UserDefaultsKeys+Extension.swift
//  UserDefaultsWrapperProject
//
//  Created by 김건우 on 7/27/25.
//

import Foundation

struct UserDefaultsKeys { }

extension UserDefaultsKeys {

    /// 사용자가 온보딩 화면을 본 적이 있는지를 나타내는 불리언 값입니다.
    var hasSeenOnboarding: UserDefaultsKey<Bool> {
        UserDefaultsKey<Bool>(
            "hasSeenOnboarding",
            defaultValue: false
        )
    }

    var healthkitLinked: UserDefaultsKey<Bool> {
        UserDefaultsKey<Bool>(
            "HealthKitLinked",
            defaultValue: false
        )
    }

    /// PersonalView에서 월간 AI 요약 Label은 하루동안 캐시에 저장됩니다.
    var aiSummaryMessage: UserDefaultsKey<String?> {
        UserDefaultsKey<String?>(
            "AISummary_Message",
            defaultValue: nil
        )
    }

    var aiSummaryDate: UserDefaultsKey<String?> {
        UserDefaultsKey<String?>(
            "AISummary_Date",
            defaultValue: nil
    
    var appThemeStyle: UserDefaultsKey<Int> {
        UserDefaultsKey<Int>(
            "appThemeStyle",
            defaultValue: AppTheme.system.rawValue

        )
    }
}
