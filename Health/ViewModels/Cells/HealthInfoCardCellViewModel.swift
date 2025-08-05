//
//  HealthInfoCardCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Foundation

struct HealthInfoCardCellViewModel {
    let id = UUID().uuidString
}

extension HealthInfoCardCellViewModel: Hashable {
}
