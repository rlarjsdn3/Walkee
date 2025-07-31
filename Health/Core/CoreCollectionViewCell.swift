//
//  CoreCollectionViewCell.swift
//  Health
//
//  Created by juks86 on 7/30/25.
//

import UIKit

/// 공통 컬렉션뷰 셀의 기반 클래스입니다.
///
/// 셀을 커스터마이징할 때, 초기화 흐름을 재사용할 수 있도록 합니다.
class CoreCollectionViewCell: UICollectionViewCell {

    /// 스토리보드 또는 Nib 파일에서 셀이 로드될 때 호출됩니다.
    ///
    /// 기본 구현에서는 `setupHierarchy`, `setupAttribute`, `setupConstraints`를 순서대로 실행합니다.
    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            setupHierarchy()
            setupAttribute()
            setupConstraints()
        }
    }

    /// 셀의 서브뷰를 `contentView`에 추가하는 메서드.
    ///
    /// 기본 구현은 비어 있으며, 서브클래스에서 오버라이드하여 사용합니다.
    func setupHierarchy() {}

    /// 셀의 속성을 설정하는 메서드.
    ///
    /// 예: 배경색, 텍스트 색상, 폰트 등을 설정합니다.
    /// 기본 구현에서는 배경색을 투명으로 설정합니다.
    func setupAttribute() { backgroundColor = .clear }

    /// Auto Layout 제약 조건을 설정하는 메서드.
    ///
    /// NSLayoutConstraint 또는 다른 레이아웃 도구를 사용하여 셀의 레이아웃을 정의합니다.
    /// 기본 구현은 비어 있으며, 서브클래스에서 오버라이드하여 사용합니다.
    func setupConstraints() {}
}
