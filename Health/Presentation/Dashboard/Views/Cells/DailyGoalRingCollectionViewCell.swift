//
//  DailyGoalRingCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import UIKit

final class DailyGoalRingCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var circleProgressView: CircleProgressView!

}

extension DailyGoalRingCollectionViewCell {

    func bind(with viewModel: DailyGoalRingCellViewModel) {
        Task {
            do {
                circleProgressView.totalValue = viewModel.goalStepCount
                circleProgressView.currentValue = try await viewModel.fetchStatisticsHKData().value
            } catch {
                // TODO: - 예외 UI 코드 작성하기
                print("🔴 Failed to fetch statistics HKData: \(error)")
            }
        }
    }
}
