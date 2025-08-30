//
//  EditDiseaseCollectionViewCell.swift
//  Health
//
//  Created by 하재준 on 8/20/25.
//
import UIKit

final class EditDiseaseCollectionViewCell: CoreCollectionViewCell {
    
    let diseaseLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .medium)
        l.textAlignment = .center
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupAttribute()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = .accent
                diseaseLabel.textColor = .systemBackground
                diseaseLabel.font = .systemFont(ofSize: diseaseLabel.font.pointSize, weight: .bold)
            } else {
                contentView.backgroundColor = .boxBg
                diseaseLabel.textColor = .white
                diseaseLabel.font = .systemFont(ofSize: diseaseLabel.font.pointSize, weight: .medium)
                updateUIForCurrentTrait()
            }
        }
    }
    
    
    override func setupHierarchy() {
        contentView.addSubview(diseaseLabel)
        contentView.layer.masksToBounds = true
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        contentView.backgroundColor = .boxBg
        contentView.layer.cornerRadius = 12
        contentView.layer.cornerCurve = .continuous
                
        updateUIForCurrentTrait()
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            diseaseLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            diseaseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            diseaseLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
    }
    
    func configure(_ disease: Disease) {
        diseaseLabel.text = disease.localizedName
    }
    
    private func updateUIForCurrentTrait() {
        if traitCollection.userInterfaceStyle == .dark {
            diseaseLabel.textColor = .white
            contentView.layer.borderColor = UIColor.clear.cgColor
        } else {
            diseaseLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
            contentView.layer.borderColor = UIColor.boxBgLightModeStroke.cgColor
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if !isSelected {
            updateUIForCurrentTrait()
        }
        
    }
}
