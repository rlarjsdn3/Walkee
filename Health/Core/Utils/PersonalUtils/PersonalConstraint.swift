//
//  PersonalConstraint.swift
//  Health
//
//  Created by juks86 on 8/12/25.
//

import UIKit

/// 기기와 방향에 따른 백그라운드 높이 계산 유틸리티
final class BackgroundHeightUtils {

    /// 기기와 방향에 따른 백그라운드 높이를 계산합니다
    @MainActor static func calculateBackgroundHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        let heightRatio: CGFloat

        if UIDevice.current.userInterfaceIdiom == .pad {
            if screenWidth > screenHeight {
                // iPad 가로: 더 작은 비율
                heightRatio = 0.18  // 18%
            } else {
                // iPad 세로: 기본 비율
                heightRatio = 0.20  // 20%
            }
        } else {
            // iPhone: 기본 비율
            heightRatio = 0.25
        }

        return screenHeight * heightRatio
    }

    /// 제약 조건을 업데이트하고 애니메이션을 적용합니다
    @MainActor static func updateBackgroundHeight(constraint: NSLayoutConstraint, in view: UIView) {
        constraint.constant = calculateBackgroundHeight()

        UIView.animate(withDuration: 0.3) {
            view.layoutIfNeeded()
        }
    }
}
