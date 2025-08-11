//
//  DashboardTopBarCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

final class DashboardTopBarCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var weekDayLabel: UILabel!
    @IBOutlet weak var anchorDateLabel: UILabel!

    override func setupAttribute() {
        super.setupAttribute()

        dateLabel.text = Date.now.formatted(using: .md)
        weekDayLabel.text = Date.now.formatted(using: .weekday)
        anchorDateLabel.text = "(\(Date.now.formatted(using: .h_m)) 기준)"
    }
}

extension DashboardTopBarCollectionViewCell {

    func update(with date: Date) {
        dateLabel.text = date.formatted(using: .md)
        weekDayLabel.text = date.formatted(using: .weekday)
        anchorDateLabel.text = "(\(date.formatted(using: .h_m)) 기준)"
    }
}
