//
//  UIView+CornerRadius.swift
//  Health
//
//  Created by juks86 on 8/5/25.
//

import UIKit
/// 코너 반지름 값들
struct CornerRadius {
    /// 작은 코너 반지름 (작은 카드)
    static let small: CGFloat = 8.0

    /// 기본 코너 반지름 (일반 카드, 컨테이너)
    static let medium: CGFloat = 12.0

    /// 큰 코너 반지름 (메인 카드, 큰 컨테이너)
    static let large: CGFloat = 14.0

    /// 원형 (버튼, 프로필 이미지 등)
    // circular은 동적 계산: min(width, height) / 2
}

extension UIView {

    /// 미리 정의된 코너 스타일을 적용합니다
    enum CornerStyle {
        case small      // 8pt
        case medium     // 12pt
        case large      // 14pt
        case circular   // width/2
        case custom(CGFloat) // 커스텀 값
    }

    /// UIView의 모서리를 다양한 스타일로 설정합니다.
    ///
    /// - Note: `.circular` 스타일은 뷰가 정사각형일 경우에만 완전한 원이 됩니다.
    ///         이 스타일은 뷰의 레이아웃이 확정된 이후(`layoutIfNeeded()` 호출 후)에 적용해야 정확합니다.
    func applyCornerStyle(_ style: CornerStyle) {
        switch style {
            case .small:
                layer.cornerRadius = CornerRadius.small

            case .medium:
                layer.cornerRadius = CornerRadius.medium

            case .large:
                layer.cornerRadius = CornerRadius.large

            case .circular:
                // 레이아웃이 아직 반영되지 않았을 수 있으므로 먼저 강제 layout 수행
                layoutIfNeeded()
                layer.cornerRadius = min(bounds.width, bounds.height) / 2

            case .custom(let radius):
                layer.cornerRadius = radius
        }

        // cornerRadius 적용 시 마스킹도 반드시 켜줘야 실제로 적용됨
        layer.masksToBounds = true
        clipsToBounds = true
    }
}
// MARK: - 사용법 요약 주석
/*
 //버튼
 saveButton.applyCornerStyle(.medium)           // 저장 버튼
 cancelButton.applyCornerStyle(.small)          // 취소 버튼
 profileImageButton.applyCornerStyle(.circular) // 프로필 버튼 (원형)

 // 뷰 컨테이너
 cardView.applyCornerStyle(.large)              // 메인 카드
 sectionView.applyCornerStyle(.medium)          // 섹션 컨테이너
 tooltipView.applyCornerStyle(.small)           // 작은 툴팁
 )
 */

