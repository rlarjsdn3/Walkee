//
//  PersonalConstraint.swift
//  Health
//
//  Created by juks86 on 8/12/25.
//

import UIKit

/// 기기와 방향에 따른 백그라운드 높이 계산 유틸리티
@MainActor
final class BackgroundHeightUtils {
    
    /// 기기와 방향에 따른 백그라운드 높이를 계산합니다
    static func calculateBackgroundHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        
        let heightRatio: CGFloat
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if screenWidth > screenHeight {
                // iPad 가로
                heightRatio = 0.25  // 25%
            } else {
                // iPad 세로
                heightRatio = 0.20  // 20%
            }
        } else {
            // iPhone
            heightRatio = 0.25
        }
        
        return screenHeight * heightRatio
    }
    
    /// 제약 조건을 업데이트하고 애니메이션을 적용합니다
    static func updateBackgroundHeight(constraint: NSLayoutConstraint, in view: UIView) {
        constraint.constant = calculateBackgroundHeight()
        
        UIView.animate(withDuration: 0.3) {
            view.layoutIfNeeded()
        }
    }
    
    // MARK: - 테두리 관련
    /// 다크모드/라이트모드에 따른 테두리 두께를 계산합니다
    /// - Parameter traitCollection: 현재 trait collection
    /// - Returns: 다크모드일 때 0, 라이트모드일 때 0.75
    static func calculateBorderWidth(for traitCollection: UITraitCollection) -> CGFloat {
        return (traitCollection.userInterfaceStyle == .dark) ? 0 : 0.75
    }
    
    /// 뷰에 다크모드 대응 테두리를 설정합니다
    /// - Parameter view: 테두리를 설정할 뷰
    static func setupDarkModeBorder(for view: UIView) {
        // 초기 테두리 설정
        view.layer.borderWidth = calculateBorderWidth(for: view.traitCollection)
        view.layer.borderColor = UIColor.boxBgLightModeStroke.cgColor
        view.layer.masksToBounds = true
        
        // 다크모드/라이트모드 전환 감지 등록
        view.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: UIView, previousTraitCollection: UITraitCollection) in
            // 모드 전환 시 테두리 두께 업데이트
            view.layer.borderWidth = calculateBorderWidth(for: view.traitCollection)
        }
    }
    
    static func setupShadow(for view: UIView) {
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 2, height: 2)
        view.layer.shadowRadius = 5
    }
}
