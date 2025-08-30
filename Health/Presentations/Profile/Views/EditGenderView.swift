//
//  EditGenderView.swift
//  Health
//
//  Created by 하재준 on 8/9/25.
//

import UIKit

final class EditGenderView: CoreView {
    
    enum Gender: String, CaseIterable {
        case female = "여성"
        case male = "남성"
    }
    
    
    private let buttonSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.25
    
    var selectedGender: Gender? {
        didSet {
            updateButtonConfig()
        }
    }
    
    private let titleLabel = UILabel()
    
    private lazy var femaleButton = createGenderButton(for: .female)
    private lazy var maleButton = createGenderButton(for: .male)
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [femaleButton, maleButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 35
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        
        titleLabel.configureAsTitle("성별")
    }
    
    override func setupHierarchy() {
        addSubviews(titleLabel, stackView)
    }
    
    override func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 12),
            stackView.heightAnchor.constraint(equalToConstant: 300),
            
            femaleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            femaleButton.heightAnchor.constraint(equalToConstant: buttonSize),
            
            maleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            maleButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            setNeedsLayout()
        }
    }
    
    private func createGenderButton(for gender: Gender) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(gender.rawValue, for: .normal)
        button.setTitleColor(.systemBackground, for: .normal)
        button.backgroundColor = .buttonBackground
        button.titleLabel?.font = UIDevice.current.userInterfaceIdiom == .pad
        ? .preferredFont(forTextStyle: .largeTitle).withBoldTrait()
        : .systemFont(ofSize: 18, weight: .bold)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.clipsToBounds = true
        button.layer.cornerRadius = buttonSize / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(genderButtonTapped(_:)), for: .touchUpInside)
        button.tag = Gender.allCases.firstIndex(of: gender) ?? 0
        return button
    }
    
    func setDefaultGender(_ gender: Gender?) {
        selectedGender = gender
    }
    
    @objc private func genderButtonTapped(_ sender: UIButton) {
        guard let gender = Gender.allCases[safe: sender.tag] else { return }
        selectedGender = gender
    }
    
    private func updateButtonConfig() {
        let selectedTextColor = UIColor.systemBackground
        let defaultTextColor = UIColor.label
        
        femaleButton.backgroundColor = (selectedGender == .female) ? .accent : .systemGray5
        maleButton.backgroundColor = (selectedGender == .male) ? .accent : .systemGray5
        
        femaleButton.setTitleColor((selectedGender == .female) ? selectedTextColor : defaultTextColor, for: .normal)
        maleButton.setTitleColor((selectedGender == .male) ? selectedTextColor : defaultTextColor, for: .normal)
    }
}
