//
//  EditGenderView.swift
//  Health
//
//  Created by 하재준 on 8/9/25.
//

import UIKit

class EditGenderView: UIView {
    
    private let mintColor = UIColor.accent
    private let grayColor = UIColor.buttonBackground
    
    private let buttonSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.25

    
    private lazy var femaleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("여성", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = grayColor
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.clipsToBounds = true
        button.layer.cornerRadius = buttonSize / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(femaleTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var maleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("남성", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = grayColor
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.clipsToBounds = true
        button.layer.cornerRadius = buttonSize / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(maleTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [femaleButton, maleButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 35
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            setNeedsLayout()
        }
    }

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 300),
            
            femaleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            femaleButton.heightAnchor.constraint(equalToConstant: buttonSize),
            
            maleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            maleButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func femaleTapped() {
        femaleButton.backgroundColor = mintColor
        maleButton.backgroundColor = grayColor
    }
    
    @objc private func maleTapped() {
        maleButton.backgroundColor = mintColor
        femaleButton.backgroundColor = grayColor
    }
}
