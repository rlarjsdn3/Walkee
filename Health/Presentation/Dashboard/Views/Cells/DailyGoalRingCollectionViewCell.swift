//
//  DailyGoalRingCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import Combine
import UIKit

final class DailyGoalRingCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var circleProgressView: CircleProgressView!

    private var cancalleable: Set<AnyCancellable> = []

    private var viewModel: DailyGoalRingCellViewModel!

    override func prepareForReuse() {
        cancalleable.removeAll()
    }
}

extension DailyGoalRingCollectionViewCell {

    func bind(with viewModel: DailyGoalRingCellViewModel) {
        self.viewModel = viewModel

        viewModel.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(for: state) }
            .store(in: &cancalleable)
    }

    private func render(for state: LoadState<GoalRingContent>) {
        switch state {
        case .idle:
            return // TODO: - 플레이스 홀더 UI 구성하기

        case .loading:
            return // TODO: - 스켈레톤 UI 구성하기

        case let .success(content):
            circleProgressView.totalValue = Double(content.goalStepCount)
            circleProgressView.currentValue = Double(content.currentStepCount)

        case .failure:
            circleProgressView.currentValue = nil
            print("🔴 건강 데이터를 불러오는 데 실패함: DailyGoalRingCell")

        case .denied:
            circleProgressView.currentValue = nil
            print("🔵 건강 데이터에 접근할 수 있는 권한이 없음: DailyGoalRingCell")
        }
    }
}
