//
//  LoadState.swift
//  Health
//
//  Created by 김건우 on 8/12/25.
//

import Foundation

enum LoadState<Value> where Value: Equatable {
    ///
    case idle
    ///
    case loading
    ///
    case success(Value)
    ///
    case failure(Error)
}

extension LoadState: Equatable {

    static func == (lhs: LoadState<Value>, rhs: LoadState<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (let .success(value1), let .success(value2)):
            return value1 == value2
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
}
