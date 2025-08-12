//
//  AlanActivitySummaryCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import HealthKit

typealias AlanContent = AlanActivitySummaryCellViewModel.Content

final class AlanActivitySummaryCellViewModel {

    ///
    struct ItemID: Hashable {
        let id: UUID = UUID()
    }

    ///
    struct Content: Hashable {
        let message: String
    }

    ///
    private(set) var itemID: ItemID

    ///
    private let stateSubject = CurrentValueSubject<LoadState<AlanContent>, Never>(.idle)

    ///
    var statePublisher: AnyPublisher<LoadState<AlanContent>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    ///
    var didChange: ((ItemID) -> Void)?

    ///
    init(itemID: ItemID) {
        self.itemID = itemID
    }

    ///
    func setState(_ new: LoadState<AlanContent>) {
        stateSubject.send(new)
        didChange?(itemID)
    }
}

extension AlanActivitySummaryCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    nonisolated static func == (lhs: AlanActivitySummaryCellViewModel, rhs: AlanActivitySummaryCellViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
