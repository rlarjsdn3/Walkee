//
//  DashboardBarChartsCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import HealthKit

final class DashboardBarChartsCellViewModel { // TODO: - Cell에서 처리하고 있는 HKData 페치 로직을 VC의 VM으로 빼보기
    
    ///
    struct ItemID: Hashable {
        let id: UUID = UUID()
        let kind: BarChartsBackKind
    }
    
    ///
    private(set) var itemID: ItemID
    
    /// 섹션/막대 범위를 설명하는 헤더 타이틀
    var headerTitle: String {
        switch itemID.kind {
        case .daysBack(let n):   return "지난 \(max(0, abs(n)))일 간 걸음 수 분석"
        case .monthsBack(let n): return "지난 \(max(0, abs(n)))개월 간 걸음 수 분석"
        }
    }
    
    ///
    private let stateSubject = CurrentValueSubject<HKLoadState, Never>(.idle)
    
    ///
    var statePublisher: AnyPublisher<HKLoadState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    ///
    var didChange: ((ItemID) -> Void)?
    
    ///
    init(itemID: ItemID) {
        self.itemID = itemID
    }
    
    ///
    func setState(_ new: HKLoadState) {
        stateSubject.send(new)
        didChange?(itemID)
    }
}


extension DashboardBarChartsCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(itemID)
    }

    nonisolated static func == (lhs: DashboardBarChartsCellViewModel, rhs: DashboardBarChartsCellViewModel) -> Bool {
        return lhs.itemID.id == rhs.itemID.id
                && lhs.itemID.kind == rhs.itemID.kind
    }
}
