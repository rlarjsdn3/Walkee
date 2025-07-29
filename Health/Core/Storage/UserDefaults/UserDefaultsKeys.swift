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
}
