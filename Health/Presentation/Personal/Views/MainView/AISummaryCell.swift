//
//  AISummaryCell.swift
//  Health
//
//  Created by juks86 on 8/10/25.
//

import UIKit

class AISummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var summaryBackgroundView: UIView!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setupAttribute() {
        super.setupAttribute()
        summaryBackgroundView.applyCornerStyle(.medium)
    }
}
