//
//  DiseaseCollectionViewCell.swift
//  Health
//
//  Created by 권도현 on 8/8/25.
//


import UIKit

class DiseaseCollectionViewCell: CoreCollectionViewCell {
    
    @IBOutlet weak var diseaseLabel: UILabel!
    
    override func setupHierarchy() {
        super.setupHierarchy()
        contentView.applyCornerStyle(.medium)
        contentView.layer.masksToBounds = true
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        contentView.backgroundColor = .boxBg
        updateTextColor()
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = .accent
                diseaseLabel.textColor = .black
                diseaseLabel.font = UIFont.systemFont(ofSize: diseaseLabel.font.pointSize, weight: .bold)
            } else {
                contentView.backgroundColor = .boxBg
                updateTextColor()
                diseaseLabel.font = UIFont.systemFont(ofSize: diseaseLabel.font.pointSize, weight: .regular)
            }
        }
    }
    
    private func updateTextColor() {
        if traitCollection.userInterfaceStyle == .dark {
            diseaseLabel.textColor = .white
        } else {
            diseaseLabel.textColor = UIColor(white: 0.2, alpha: 1)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if !isSelected {
            updateTextColor()
        }
    }
}



