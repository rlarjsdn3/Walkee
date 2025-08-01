//
//  DashboardTopBarCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

final class DashboardTopBarCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet private weak var containerView: UIView!

    @IBOutlet weak var weekDayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    override func setupAttribute() {
        super.setupAttribute()

        weekDayLabel.text = Date.now.formatted(using: .weekday)
        dateLabel.text = Date.now.formatted(using: .md)

        containerView.backgroundColor = .systemBlue // for debug..
    }
}
