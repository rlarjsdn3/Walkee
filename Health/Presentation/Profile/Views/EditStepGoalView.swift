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
    
    private var repeatTimer: Timer?
    
    var step: Int = 500
    var minValue: Int = 500
    var maxValue: Int = 100_000
    var onValueChanged: ((Int) -> Void)?
    
    private let buttonDiameter: CGFloat = 72
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
        l.font = UIFont.preferredFont(forTextStyle: .title1)
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
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
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
            b.backgroundColor = .accent
            b.tintColor = .systemBackground
            b.layer.cornerRadius = buttonDiameter / 2
            b.clipsToBounds = true
            b.widthAnchor.constraint(equalToConstant: buttonDiameter).isActive = true
            b.heightAnchor.constraint(equalToConstant: buttonDiameter).isActive = true
            
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold, scale: .large)
            b.setPreferredSymbolConfiguration(config, forImageIn: .normal)
            
            let buttonConfig = UIButton.Configuration.plain()
            b.configurationUpdateHandler = { button in
                switch button.state {
                case .highlighted:
                    b.alpha = 0.75
                default:
                    b.alpha = 1.0
                }
            }
            b.configuration = buttonConfig
        }
        
        minusButton.addTarget(self, action: #selector(decrease), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(increase), for: .touchUpInside)
        
        let minusLong = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        minusLong.minimumPressDuration = 0.4
        let plusLong = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        plusLong.minimumPressDuration = 0.4

        minusButton.addGestureRecognizer(minusLong)
        plusButton.addGestureRecognizer(plusLong)
    }
    
    private func updateUI() {
        valueLabel.text = formatter.string(from: NSNumber(value: value))
        minusButton.isEnabled = value > minValue
        plusButton.isEnabled  = value < maxValue
    }
    
    func configure(defaultValue: Int, step: Int = 500, min: Int = 500, max: Int = 100_000) {
        self.step = step
        self.minValue = min
        self.maxValue = max
        self.value = defaultValue
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }

        switch gesture.state {
        case .began:
            repeatTimer?.invalidate()
            let t = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    if button == self.minusButton {
                        self.decrease()
                    } else if button == self.plusButton {
                        self.increase()
                    }
                }
            }
            RunLoop.current.add(t, forMode: .common)
            repeatTimer = t

        case .ended, .cancelled, .failed:
            repeatTimer?.invalidate()
            repeatTimer = nil

        default:
            break
        }
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
