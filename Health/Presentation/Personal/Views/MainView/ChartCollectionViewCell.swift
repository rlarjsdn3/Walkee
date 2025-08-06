//
//  ChartCollectionViewCell.swift
//  Health
//
//  Created by juks86 on 8/6/25.
//

import UIKit

class ChartCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var dataContainer: UIView!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var walkingLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setupConstraints() {
        super.setupConstraints()
        chartView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // chartView 너비 = dataContainer의 50%
            chartView.widthAnchor.constraint(equalTo: dataContainer.widthAnchor, multiplier: 0.5)
        ])
    }
}

