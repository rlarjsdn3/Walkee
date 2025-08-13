//
//  DailyGoalRingCellViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import Foundation

typealias GoalRingContent = DailyGoalRingCellViewModel.Content

final class DailyGoalRingCellViewModel {

    ///
    struct ItemID: Hashable {
        let id: UUID = UUID()
    }

    ///
    struct Content: Equatable {
        let goalStepCount: Int
        let currentStepCount: Int
    }

    ///
    private(set) var itemID: ItemID

    ///
    private let stateSubject = CurrentValueSubject<LoadState<GoalRingContent>, Never>(.idle)

    ///
    var statePublisher: AnyPublisher<LoadState<GoalRingContent>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    ///
    var didChange: ((ItemID) -> Void)?


    ///
    init(itemID: ItemID) {
        self.itemID = itemID
    }

    ///
    func setState(_ new: LoadState<GoalRingContent>) {
        stateSubject.send(new)
        didChange?(itemID)
    }
}

extension DailyGoalRingCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(itemID)
    }

    nonisolated static func == (lhs: DailyGoalRingCellViewModel, rhs: DailyGoalRingCellViewModel) -> Bool {
        return lhs.itemID == rhs.itemID
    }
}
