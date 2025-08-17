//
//  DiseaseCollectionViewCell.swift
//  Health
//
//  Created by 권도현 on 8/8/25.
//


import UIKit

class DiseaseCollectionViewCell: CoreCollectionViewCell {
    
    @IBOutlet weak var diseaseLabel: UILabel!
    
    private var traitChangeRegistration: Any?
    
    override func setupHierarchy() {
        super.setupHierarchy()
        contentView.applyCornerStyle(.medium)
        contentView.layer.masksToBounds = true
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        contentView.backgroundColor = .boxBg
        updateTextColor()
        diseaseLabel.font = .systemFont(ofSize: 16)

        if #available(iOS 17.0, *) {
            traitChangeRegistration = registerForTraitChanges(
                [UITraitUserInterfaceStyle.self]
            ) { [weak self] (cell: DiseaseCollectionViewCell, previousTraitCollection: UITraitCollection) in
                guard let self = self else { return }
                if !self.isSelected {
                    self.updateTextColor()
                }
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = .accent
                diseaseLabel.textColor = .black
                diseaseLabel.font = .boldSystemFont(ofSize: 16)
            } else {
                contentView.backgroundColor = .boxBg
                updateTextColor()
                diseaseLabel.font = .systemFont(ofSize: 16)
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
        if #unavailable(iOS 17.0) {
            if !isSelected {
                updateTextColor()
            }
        }
    }
}


