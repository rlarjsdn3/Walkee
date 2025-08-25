//
//  UIApplication+Extension.swift
//  Health
//
//  Created by 김건우 on 8/25/25.
//

import UIKit

extension UIApplication {

    /// 현재 앱의 키 윈도우가 세로 방향인지 여부를 반환합니다.
    var isPortrait: Bool {
        for scene in connectedScenes {
            guard let windowScene = scene as? UIWindowScene
            else { continue }

            if windowScene.windows.isEmpty {
                continue
            }

            if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow.windowScene?.interfaceOrientation.isPortrait ?? false
            }
        }
        return false
    }
}
