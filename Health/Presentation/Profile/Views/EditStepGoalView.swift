//
//  EditStepGoalView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit

final class EditStepGoalView: CoreView {
    
    let titleLabel = UILabel()
    
    var value: Int = 0 {
        didSet {
            value = max(minValue, min(maxValue, value))
            if oldValue != value {
                updateUI()
                onValueChanged?(value)
            }
        }
    }
    
    var step: Int = 500
    var minValue: Int = 0
    var maxValue: Int = 100_000
    var onValueChanged: ((Int) -> Void)?
    
    private let buttonDiameter: CGFloat = 72
    private let accentColor: UIColor = .accent
    private let valueFontSize: CGFloat = 88
    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let stack = UIStackView()
    
    private lazy var formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.5
        l.numberOfLines = 1
        return l
    }()
    
    private let unitLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .secondaryLabel
        l.font = .preferredFont(forTextStyle: .title3)
        return l
    }()
    
    private let valueStack = UIStackView()
    private let hStack = UIStackView()
    
    override func setupHierarchy() {
        valueStack.addArrangedSubview(valueLabel)
        valueStack.addArrangedSubview(unitLabel)
        
        hStack.addArrangedSubview(minusButton)
        hStack.addArrangedSubview(valueStack)
        hStack.addArrangedSubview(plusButton)
        
        addSubviews(titleLabel, hStack)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        
        titleLabel.configureAsTitle("목표 걸음")
        setupConfigure()
        setupButtons()
        updateUI()
        
    }
    
    
    override func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontalPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 160 : 16
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            hStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding)

        ])
    }
    
    private func setupConfigure() {
        valueStack.axis = .vertical
        valueStack.alignment = .center
        valueStack.spacing = 8
        
        valueLabel.font = .preferredFont(forTextStyle: .largeTitle)
        valueLabel.adjustsFontForContentSizeCategory = true
        
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 24
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        unitLabel.text = "걸음"
    }
    
    private func setupButtons() {
        minusButton.setImage(UIImage(systemName: "minus"), for: .normal)
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        
        [minusButton, plusButton].forEach { b in
            b.translatesAutoresizingMaskIntoConstraints = false
            b.tintColor = .white
            b.backgroundColor = accentColor
            b.tintColor = .systemBackground
            b.layer.cornerRadius = buttonDiameter / 2
            b.clipsToBounds = true
            b.widthAnchor.constraint(equalToConstant: buttonDiameter).isActive = true
            b.heightAnchor.constraint(equalToConstant: buttonDiameter).isActive = true
            
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold, scale: .large)
            b.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        }
        
        minusButton.addTarget(self, action: #selector(decrease), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(increase), for: .touchUpInside)
    }
    
    private func updateUI() {
        valueLabel.text = formatter.string(from: NSNumber(value: value))
        minusButton.isEnabled = value > minValue
        plusButton.isEnabled  = value < maxValue
    }
    
    func configure(defaultValue: Int, step: Int = 500, min: Int = 0, max: Int = 100_000) {
        self.step = step
        self.minValue = min
        self.maxValue = max
        self.value = defaultValue
    }
    
    @objc private func decrease() {
        value -= step
    }
    
    @objc private func increase() {
        value += step
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: 320, height: buttonDiameter + 40)
    }
}
