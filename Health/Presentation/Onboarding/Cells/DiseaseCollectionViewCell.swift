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
        updateUIForCurrentState()
    }
    
    override var isSelected: Bool {
        didSet {
            updateUIForCurrentState()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateUIForCurrentState()
    }
    
    private func updateUIForCurrentState() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if isSelected {
            contentView.backgroundColor = .accent
            diseaseLabel.textColor = .black
            diseaseLabel.font = diseaseLabel.font.withBoldTrait()
        } else {
            contentView.backgroundColor = .boxBg
            diseaseLabel.textColor = isDarkMode ? .white : UIColor(white: 0.2, alpha: 1)
            diseaseLabel.font = diseaseLabel.font.withNormalTrait()
        }
    }
}
