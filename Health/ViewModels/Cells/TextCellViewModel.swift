//
//  TextCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Foundation

struct TextCellViewModel {
    let id = UUID().uuidString
}

extension TextCellViewModel: Hashable {
}
