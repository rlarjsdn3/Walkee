//
//  KeychainWrapperKeys+Extension.swift
//  KeychainWrapperProject
//
//  Created by 김건우 on 7/27/25.
//

import Foundation

struct KeychainKeys { }

extension KeychainKeys {
    
    /// 사용자 비밀번호를 저장하거나 불러올 때 사용하는 키입니다.
    var password: KeychainKey<String> {
        KeychainKey(name: "password")
    }
}

