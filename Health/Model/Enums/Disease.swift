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
    case stroke
    case muscularDystrophy
    case multipleSclerosis
    case peripheralNeuropathy
    case chronicPain
    case fracture

    var localizedName: String {
        switch self {
        case .arthritis: return "관절염"
        case .parkinsons: return "파킨슨병"
        case .stroke: return "뇌졸중"
        case .muscularDystrophy: return "근이영양증"
        case .multipleSclerosis: return "다발성 경화증"
        case .peripheralNeuropathy: return "말초신경병증"
        case .chronicPain: return "만성통증"
        case .fracture: return "골절"
        }
    }
}
