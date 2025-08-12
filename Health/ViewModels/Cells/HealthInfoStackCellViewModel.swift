//
//  DailyActivitySummaryViewModel.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import HealthKit

final class HealthInfoStackCellViewModel {

    /// 셀을 식별하기 위한 고유 식별자입니다.
    /// `id`는 뷰모델 생성 시마다 새로운 UUID로 초기화되며,
    /// `kind`는 해당 셀이 나타낼 데이터 종류를 나타냅니다.
    struct ItemID: Hashable {
        let id: UUID = UUID()
        let kind: DashboardStackKind
    }

    /// 이 뷰모델의 고유 식별자입니다.
    let itemID: ItemID

    /// 현재 HealthKit 데이터의 로딩 상태입니다.
    /// 기본값은 `.loading`이며, `setState(_:)` 호출 시 변경됩니다.
    private(set) var state: HKLoadState<HKData> = .loading

    /// 현재 상태를 퍼블리시하는 읽기 전용 퍼블리셔입니다.
    /// - Note: 구독 시점의 상태를 즉시 전달하며, 이후 상태 변경 시 새 값을 발행합니다.
    var statePublisher: AnyPublisher<HKLoadState<HKData>, Never> {
        CurrentValueSubject(state).eraseToAnyPublisher()
    }

    /// 상태가 변경될 때 호출되는 클로저입니다.
    /// 변경된 셀의 `ItemID`를 전달하여 외부에서 UI 업데이트를 트리거할 수 있습니다.
    var didChange: ((HealthInfoStackCellViewModel.ItemID) -> Void)?

    /// 지정한 식별자를 사용하여 뷰모델을 초기화합니다.
    ///
    /// - Parameter itemID: 셀의 고유 식별자입니다.
    init(itemID: ItemID) {
        self.itemID = itemID
    }

    /// HealthKit 데이터의 로딩 상태를 변경합니다.
    ///
    /// - Parameter new: 변경할 새로운 상태입니다.
    /// - Note: 상태 변경 후 `didChange` 클로저가 호출되어 외부에 변경 사실을 알립니다.
    func setState(_ new: HKLoadState<HKData>) {
        state = new
        didChange?(itemID)
    }
}

extension HealthInfoStackCellViewModel: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(itemID)
    }

    nonisolated static func == (lhs: HealthInfoStackCellViewModel, rhs: HealthInfoStackCellViewModel) -> Bool {
        return lhs.itemID.id == rhs.itemID.id
                && lhs.itemID.kind == rhs.itemID.kind
    }
}
