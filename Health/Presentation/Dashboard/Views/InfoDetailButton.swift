//
//  InfoDetailButton.swift
//  Health
//
//  Created by 김건우 on 8/7/25.
//

import UIKit

final class InfoDetailButton: UIButton {

    ///
    var touchHandler: ((UIAction) -> Void)?

    ///
    convenience init(touchHandler: @escaping ((UIAction) -> Void)) {
        self.init(frame: .zero)

        self.touchHandler = touchHandler
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setConfiguration()
        addButtonTouchHandler()

        self.configurationUpdateHandler = { button in
            switch button.state {
            case .normal: self.layer.opacity = 1.0
            default: self.layer.opacity = 0.5
            }
        }
    }

    private func setConfiguration() {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "info.circle.fill")? // TODO: - 다른 이미지로 변경할 수 있도록 속성 제공하기
            .applyingSymbolConfiguration(.init(paletteColors: [.systemGray2]))
        config.baseBackgroundColor = .clear
        config.background.backgroundColor = .clear
        self.configuration = config
    }

    private func addButtonTouchHandler() {
        self.addAction(UIAction(handler: { [weak self] action in
            self?.touchHandler?(action)
        }), for: .touchUpInside)
    }
}
