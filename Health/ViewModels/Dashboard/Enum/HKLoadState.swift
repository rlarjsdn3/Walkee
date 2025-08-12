//
//  HKLoadState.swift
//  Health
//
//  Created by 김건우 on 8/12/25.
//

import Foundation

enum HKLoadState<Value> where Value: Equatable {
    ///
    case loading
    ///
    case success(data: Value, collection: [Value]? = nil)
    ///
    case failure(Error?)
}

extension HKLoadState: Equatable {

    static func == (lhs: HKLoadState<Value>, rhs: HKLoadState<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (let .success(data1, collection1), let .success(data2, collection2)):
            return data1 == data2 && collection1 == collection2
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
}
