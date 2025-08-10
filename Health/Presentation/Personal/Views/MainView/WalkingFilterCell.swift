//
//  WalkingFilterCell.swift
//  Health
//
//  Created by juks86 on 8/6/25.
//

import UIKit

class WalkingFilterCell: CoreCollectionViewCell {

    @IBOutlet weak var level1Label: UIButton!
    @IBOutlet weak var level2Label: UIButton!
    @IBOutlet weak var level3Label: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setupConstraints() {
        super.setupConstraints()
        level1Label.applyCornerStyle(.medium)
        level2Label.applyCornerStyle(.medium)
        level3Label.applyCornerStyle(.medium)
    }
}
