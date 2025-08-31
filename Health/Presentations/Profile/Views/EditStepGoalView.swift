//
//  EditStepGoalView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit
import QuartzCore

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
    
    private var accelTimer: DispatchSourceTimer?
    private var pressStart: CFTimeInterval = 0
    private var lastStep: CFTimeInterval = 0
    private weak var acceleratingButton: UIButton?
    
    private let baseRepeatInterval: CFTimeInterval = 0.15  // 시작 간격(초)
    private let minRepeatInterval: CFTimeInterval  = 0.05  // 최소 간격(초)
    private let accelerationPerSec: CFTimeInterval = 0.03  // 초당 간격 감소폭(초)
    private let pollingInterval: DispatchTimeInterval = .milliseconds(16)
    
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private var lastHaptic: CFTimeInterval = 0
    private let minHapticInterval: CFTimeInterval = 0.07

    
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
    
    deinit {
        accelTimer?.cancel()
    }
    
    private func setupConfigure() {
        valueStack.axis = .vertical
        valueStack.alignment = .center
        valueStack.spacing = 8
        
        let font = UIFont.monospacedDigitSystemFont(ofSize: 34, weight: .regular)
        valueLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
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
                button.alpha = button.isHighlighted ? 0.75 : 1.0
            }
            b.configuration = buttonConfig
        }
        
        minusButton.addTarget(self, action: #selector(decrease), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(increase), for: .touchUpInside)
        
        let minusLong = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        minusLong.minimumPressDuration = 0.4
        minusLong.cancelsTouchesInView = false
        minusLong.delaysTouchesBegan = false

        let plusLong = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        plusLong.minimumPressDuration = 0.4
        plusLong.cancelsTouchesInView = false
        plusLong.delaysTouchesBegan = false

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
    
    /// 주어진 버튼에 대해 가속 반복 입력(accelerating repeat input)을 시작합니다.
    ///
    /// 버튼을 길게 누르고 있는 동안 일정 간격으로 `increase()` 또는 `decrease()`를
    /// 호출하며, 시간이 지남에 따라 호출 주기가 점차 짧아져 가속 효과를 줍니다.
    ///
    /// - Parameters:
    ///   - button: 가속 입력을 적용할 버튼 (`minusButton`이면 `decrease()`, 그렇지 않으면 `increase()` 실행).
    ///
    /// - Note:
    ///   - 이전에 동작 중이던 가속 입력은 먼저 `stopAccelerating()`으로 중지합니다.
    ///   - `DispatchSourceTimer`를 사용해 `pollingInterval` 주기로 실행 상태를 확인합니다.
    ///   - 버튼이 비활성화되면 자동으로 가속 입력을 중지합니다.
    @MainActor
    private func startAccelerating(for button: UIButton) {
        stopAccelerating()
        acceleratingButton = button
        pressStart = CACurrentMediaTime()
        lastStep = pressStart - baseRepeatInterval

        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: pollingInterval)

        t.setEventHandler { [weak self] in
            guard let self = self, let btn = self.acceleratingButton else { return }
            let now = CACurrentMediaTime()
            let elapsed = now - self.pressStart

            let currentInterval = max(self.minRepeatInterval,
                                      self.baseRepeatInterval - self.accelerationPerSec * elapsed)

            if now - self.lastStep >= currentInterval {
                Task { @MainActor in
                    if btn === self.minusButton {
                        self.decrease()
                    } else {
                        self.increase()
                    }
                }
                self.lastStep = now

                if !(btn.isEnabled) {
                    self.stopAccelerating()
                }
            }
        }

        t.resume()
        accelTimer = t
    }

    /// 가속 반복 입력(accelerating repeat input)을 중지합니다.
    ///
    /// - 현재 동작 중인 `DispatchSourceTimer`를 취소하고 해제합니다.
    /// - 가속 입력 대상으로 설정된 버튼(`acceleratingButton`)도 초기화합니다.
    @MainActor
    private func stopAccelerating() {
        accelTimer?.cancel()
        accelTimer = nil
        acceleratingButton = nil
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }

        switch gesture.state {
        case .began:
            selectionFeedback.prepare()
            startAccelerating(for: button)

        case .ended, .cancelled, .failed:
            stopAccelerating()

        default:
            break
        }
    }
    
    @MainActor
    private func fireHaptic() {
        let now = CACurrentMediaTime()
        guard now - lastHaptic >= minHapticInterval else { return }
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare() // 다음 진동 대비
        lastHaptic = now
    }
    
    @objc private func decrease() {
        value -= step
        fireHaptic()
    }
    
    @objc private func increase() {
        value += step
        fireHaptic()
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: 320, height: buttonDiameter + 40)
    }
}
