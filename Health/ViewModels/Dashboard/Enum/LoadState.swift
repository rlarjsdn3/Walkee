//
//  LoadState.swift
//  Health
//
//  Created by 김건우 on 8/12/25.
//

import Foundation

typealias HKLoadState = LoadState<HKData>

enum LoadState<Value> where Value: Equatable {
    ///
    case idle
    ///
    case loading
    ///
    case success(data: Value? = nil, collection: [Value]? = nil)
    ///
    case failure(Error? = nil)
}

extension LoadState: Equatable {

    static func == (lhs: LoadState<Value>, rhs: LoadState<Value>) -> Bool {
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
