//
//  DashboardTopBarCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

final class DashboardTopBarCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func setupAttribute() {
        super.setupAttribute()

        titleLabel.text = "Hello, World!"
        containerView.backgroundColor = .systemBlue
    }
}
