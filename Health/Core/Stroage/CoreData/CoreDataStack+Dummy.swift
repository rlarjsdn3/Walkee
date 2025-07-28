//
//  CoreDataStack+Dummy.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import Foundation

extension CoreDataStack {
    
    /// 디버그 환경에서만 더미 데이터를 Core Data에 삽입합니다.
    ///
    /// 이 메서드는 테스트 및 UI 미리보기용 데이터를 생성할 때 활용됩니다.
    /// 실제 운영 환경에서는 실행되지 않도록 `#if DEBUG` 조건으로 보호되어 있습니다.
    func insertDummyData() {
        #if DEBUG
        
        // 여기에 더미 데이터 삽입 로직을 구현해 주세요.
        
        #endif
    }
}
