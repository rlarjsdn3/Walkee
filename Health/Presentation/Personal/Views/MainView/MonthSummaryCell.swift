//
//  MonthSummaryCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit

class MonthSummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var monthlyBackgroundView: UIView!
    @IBOutlet weak var monthSummaryLabel: UILabel!
    @IBOutlet weak var walkingLabel: UILabel!
    @IBOutlet weak var walkingSubLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceSubLabel: UILabel!
    @IBOutlet weak var calorieLabel: UILabel!
    @IBOutlet weak var calorieSubLabel: UILabel!

    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setupAttribute() {
        super.setupAttribute()
        monthlyBackgroundView.applyCornerStyle(.medium)

        //현재 월 가져오기
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M" // 숫자 월

        let currentMonth = dateFormatter.string(from: Date())
        monthSummaryLabel.text = "\(currentMonth)월 기록 요약"
    }

    override func setupConstraints() {
        super.setupConstraints()
        BackgroundHeightUtils.updateBackgroundHeight(constraint: backgroundHeight, in: self)

        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            BackgroundHeightUtils.updateBackgroundHeight(constraint: self.backgroundHeight, in: self)
        }
    }
}
