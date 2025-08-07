//
//  MonthSummaryCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit

class MonthSummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var mothlyBackgroungView: UIView!

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
        mothlyBackgroungView.applyCornerStyle(.medium)

        //현재 월 가져오기
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M" // 숫자 월

        let currentMonth = dateFormatter.string(from: Date())
        monthSummaryLabel.text = "\(currentMonth)월 기록 요약"
    }

    override func setupConstraints() {
        super.setupConstraints()

        let screenHeight = UIScreen.main.bounds.height
        let calculatedHeight = screenHeight * 0.25
        backgroundHeight.constant = calculatedHeight

        //  백그라운드뷰 너비 설정
        mothlyBackgroungView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mothlyBackgroungView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            mothlyBackgroungView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
        ])
    }
}
