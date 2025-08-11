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

    func configure(with viewModel: DailyGoalRingCellViewModel) {
        circleProgressView.totalValue = viewModel.goalStepCount
        circleProgressView.currentValue = viewModel.currentStepCount
    }
}
