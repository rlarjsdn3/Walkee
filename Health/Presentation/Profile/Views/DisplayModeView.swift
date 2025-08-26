//
//  DisplayModeView.swift
//  Health
//
//  Created by 하재준 on 8/18/25.
//

import UIKit

enum AppTheme: Int, CaseIterable {
    case light = 0
    case dark = 1
    case system = 2
    
    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
    
    var title: String {
        switch self {
        case .light: return "라이트 모드"
        case .dark: return "다크 모드"
        case .system: return "시스템 설정"
        }
    }
}

class DisplayModeView: CoreView {
    
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private var buttons: [UIButton] = []
    private let options: [AppTheme] = [.light, .dark, .system]
    
    
    override func setupHierarchy() {
        addSubviews(titleLabel, stackView)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        
        titleLabel.configureAsTitle("화면 모드 설정")
        
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        
        let current = Self.loadSavedTheme()
        
        options.enumerated().forEach { idx, theme in
            let row = makeOptionRow(
                title: theme.title,
                tag: idx,
                selected: theme == current
            )
            stackView.addArrangedSubview(row)
        }
    }
    
    override func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }
    
    func saveTheme(_ theme: AppTheme) {
        UserDefaultsWrapper.shared.appThemeStyle = theme.rawValue
    }
    
    static func loadSavedTheme() -> AppTheme {
        let raw = UserDefaultsWrapper.shared.appThemeStyle
        return AppTheme(rawValue: raw) ?? .system
    }
    
    func applyAppTheme(_ theme: AppTheme) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = theme.uiStyle }
    }
    
    private func makeOptionRow(title: String, tag: Int, selected: Bool) -> UIView {
        let row = UIView()
        row.tag = tag
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .label
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        
        let spacer = UIView()
        
        let button = UIButton(type: .system)
        button.tag = tag
        
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: selected ? "inset.filled.circle" : "circle")
        cfg.contentInsets = .zero
        
        button.configuration = cfg
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        let h = UIStackView(arrangedSubviews: [titleLabel, spacer, button])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8
        h.distribution = .fill
        row.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),
            h.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 8),
            h.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -8),
            h.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -8)
        ])
        
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:)))
        row.addGestureRecognizer(tap)
        
        buttons.append(button)
        return row
    }
    
    private func updateSelection(selectedIndex: Int) {
        for (idx, btn) in buttons.enumerated() {
            let name = (idx == selectedIndex) ? "inset.filled.circle" : "circle"
            btn.setImage(UIImage(systemName: name), for: .normal)
        }
    }
    
    private func selectTheme(at index: Int) {
        updateSelection(selectedIndex: index)
        let theme = options[index]
        saveTheme(theme)
        applyAppTheme(theme)
    }
    
    @objc private func rowTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view else { return }
        selectTheme(at: row.tag)
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        selectTheme(at: sender.tag)
    }
}
