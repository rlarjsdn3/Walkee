//
//  Disease.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//

import Foundation

enum Disease: String, CaseIterable, Codable {
    case arthritis
    case parkinsons
    case scoliosis
    case stroke
    case vestibulardisorder
    case plantafasciitis
    case other
    case none

    var localizedName: String {
        switch self {
        case .arthritis: return "관절염"
        case .parkinsons: return "파킨슨병"
        case .scoliosis: return "척추측만증"
        case .stroke: return "뇌졸중"
        case .vestibulardisorder: return "전정기관장애"
        case .plantafasciitis: return "족저근막염"
        case .other: return "기타"
        case .none: return "없음"
        }
    }
}
