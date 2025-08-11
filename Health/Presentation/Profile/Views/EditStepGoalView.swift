//
//  EditStepGoalView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit

import UIKit

final class EditStepGoalView: UIControl {
    
    var value: Int = 0 {
        didSet {
            value = max(minValue, min(maxValue, value))
            updateUI()
            if oldValue != value {
                sendActions(for: .valueChanged)
            }
        }
    }
    
    var step: Int = 500
    var minValue: Int = 0
    var maxValue: Int = 1_000_000
    
    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let valueLabel = UILabel()
    private let stack = UIStackView()
    
    private lazy var formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        minusButton.setTitle("−", for: .normal)
        plusButton.setTitle("+", for: .normal)
        minusButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        plusButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        
        minusButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        plusButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
        minusButton.addTarget(self, action: #selector(decrease), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(increase), for: .touchUpInside)
        
        valueLabel.font = .preferredFont(forTextStyle: .largeTitle)
        valueLabel.textAlignment = .center
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.addArrangedSubview(minusButton)
        stack.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(plusButton)
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        updateUI()
    }
    
    @objc private func decrease() {
        value -= step
    }
    
    @objc private func increase() {
        value += step
    }
    
    private func updateUI() {
        valueLabel.text = formatter.string(from: NSNumber(value: value))
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: 180, height: 44)
    }
}

