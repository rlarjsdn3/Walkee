//
//  CoreCollectionReusableView.swift
//  Health
//
//  Created by juks86 on 7/30/25.
//

import UIKit
/// 공통 컬렉션뷰 Supplementary View (Header/Footer)의 기반 클래스입니다.
class CoreCollectionReusableView: UICollectionReusableView {

    /// 지정 이니셜라이저.
    ///
    /// - Parameter frame: 뷰의 프레임 정보
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupAttribute()
        setupConstraints()
    }

    /// 스토리보드 또는 XIB에서 초기화할 때 호출됩니다.
    ///
    /// - Parameter coder: 인터페이스 빌더에서 뷰를 디코딩하기 위한 객체
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupAttribute()
        setupConstraints()
    }

    /// 뷰 계층 구조를 설정하는 메서드.
    ///
    /// 서브뷰를 추가하는 역할을 하며, 기본 구현은 비어있고
    /// 서브클래스에서 오버라이드하여 사용합니다.
    func setupHierarchy() {}

    /// 뷰 속성을 설정하는 메서드.
    ///
    /// 배경색 등 시각적 요소를 설정하며, 기본 배경색은 투명입니다.
    func setupAttribute() { backgroundColor = .clear }

    /// Auto Layout 제약 조건을 설정하는 메서드.
    ///
    /// NSLayoutConstraint 등을 활용하여 레이아웃을 정의하며,
    /// 기본 구현은 비어있고 서브클래스에서 구현합니다.
    func setupConstraints() {}
}
