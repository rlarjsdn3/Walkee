//
//  HealthInfoCardCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import HealthKit

typealias InfoCardContent = HealthInfoCardCellViewModel.Content

final class HealthInfoCardCellViewModel {

    ///
    struct ItemID: Hashable {
        let id: UUID = UUID()
        let kind: DashboardCardKind
    }

    ///
    struct Content: Equatable {
        let value: Double
    }

    ///
    private(set) var anchorAge: Int
    ///
    private(set) var itemID: ItemID
    
    ///
    private let stateSubject = CurrentValueSubject<LoadState<InfoCardContent>, Never>(.idle)

    ///
    var statePublisher: AnyPublisher<LoadState<InfoCardContent>, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    ///
    var didChange: ((ItemID) -> Void)?
    
    ///
    init(itemID: ItemID, age: Int) {
        self.itemID = itemID
        self.anchorAge = age
    }
    
    ///
    func setState(_ new: LoadState<InfoCardContent>) {
        stateSubject.send(new)
        didChange?(itemID)
    }
    
    
    
    /// 주어진 측정값을 사용자의 나이와 카드 타입 기준에 따라 보행 상태로 평가합니다.
    ///
    /// - Parameter value: 평가할 측정값입니다.
    /// - Returns: 평가된 보행 상태(`GaitStatus`)를 반환합니다.
    func evaluateGaitStatus(_ value: Double) -> DashboardCardKind.GaitStatus {
        itemID.kind.status(value, age: anchorAge)
    }
}

extension HealthInfoCardCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(itemID.id)
    }

    nonisolated static func == (lhs: HealthInfoCardCellViewModel, rhs: HealthInfoCardCellViewModel) -> Bool {
        return lhs.itemID.id == rhs.itemID.id
                && lhs.itemID.kind == rhs.itemID.kind
    }
}
