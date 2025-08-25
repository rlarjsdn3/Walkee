//
//  DashboardTopBarViewModel.swift
//  Health
//
//  Created by 김건우 on 8/20/25.
//

import Combine
import HealthKit

final class DashboardTopBarViewModel {
    ///
    struct ItemID: Hashable {
        let id: UUID = UUID()
    }

    ///
    private(set) var itemID: ItemID

    ///
    private let stateSubject = CurrentValueSubject<Date, Never>(.now)

    ///
    var statePublisher: AnyPublisher<Date, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    ///
    var didChange: (() -> Void)?

    ///
    init(itemID: ItemID) {
        self.itemID = itemID
    }

    ///
    func updateAnchorDate(_ new: Date) {
        stateSubject.send(new)
        didChange?()
    }
}


extension DashboardTopBarViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(itemID)
    }

    nonisolated static func == (lhs: DashboardTopBarViewModel, rhs: DashboardTopBarViewModel) -> Bool {
        return lhs.itemID.id == rhs.itemID.id
    }
}

