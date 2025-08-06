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

    override func setupAttribute() {
        super.setupAttribute()

        dateLabel.text = Date.now.formatted(using: .md)
        weekDayLabel.text = Date.now.formatted(using: .weekday)
    }
}
