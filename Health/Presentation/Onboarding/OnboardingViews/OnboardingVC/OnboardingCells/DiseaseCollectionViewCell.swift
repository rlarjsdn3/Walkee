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
        contentView.backgroundColor = .buttonBackground
        diseaseLabel.textColor = .white
        diseaseLabel.font = .systemFont(ofSize: 16)
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = .accent
                diseaseLabel.textColor = .black
                diseaseLabel.font = .boldSystemFont(ofSize: 16)
            } else {
                contentView.backgroundColor = .buttonBackground
                diseaseLabel.textColor = .white
                diseaseLabel.font = .systemFont(ofSize: 16)
            }
        }
    }
}
