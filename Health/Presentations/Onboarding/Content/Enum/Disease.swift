//
//  Disease.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//

import Foundation

/// 사용자의 질병 정보를 정의하는 열거형
///
/// - 이 열거형은 사용자가 선택할 수 있는 다양한 질병 상태를 나타낸다.
/// - `CaseIterable`을 채택하여 모든 케이스를 배열 형태로 순회할 수 있으며,
/// - `Codable`을 채택하여 JSON 인코딩/디코딩 등 데이터 저장 및 전송에 활용 가능
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
