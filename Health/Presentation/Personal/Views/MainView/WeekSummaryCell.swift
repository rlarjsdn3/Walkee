//
//  WeekSummaryCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit

class WeekSummaryCell: CoreCollectionViewCell {
    
    
    @IBOutlet weak var weekBackgroundView: UIView!
    @IBOutlet weak var walkingLabel: UILabel!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var weekSummaryLabel: UILabel!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setupAttribute() {
        super.setupAttribute()
        weekBackgroundView.applyCornerStyle(.medium)
    }

    override func setupConstraints() {
        super.setupConstraints()
        
        let screenHeight = UIScreen.main.bounds.height
        let calculatedHeight = screenHeight * 0.25
        
        backgroundHeight.constant = calculatedHeight
    }
}
