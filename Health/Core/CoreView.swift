//
//  CoreView.swift
//  Health
//
//  Created by juks86 on 7/30/25.
//

import UIKit

/// `CoreView`는 코드 기반 UI 구성을 위한 **공통 UIView 기반 클래스**입니다.
///
/// 이 클래스를 상속하면 `setupHierarchy()`, `setupAttribute()`, `setupConstraints()`
/// 메서드를 통해 일관된 초기화 패턴을 적용할 수 있습니다.
///
/// - 초기화 시점에 호출되는 메서드 순서:
///   1. ``setupHierarchy()``
///   2. ``setupAttribute()``
///   3. ``setupConstraints()``
///
/// ### 사용 예시
/// ```swift
/// class CustomView: CoreView {
///     private let label = UILabel()
///
///     override func setupHierarchy() {
///         addSubview(label)
///     }
///
///     override func setupAttribute() {
///         super.setupAttribute()
///         label.text = "Hello"
///     }
///
///     override func setupConstraints() {
///         label.translatesAutoresizingMaskIntoConstraints = false
///         NSLayoutConstraint.activate([
///             label.centerXAnchor.constraint(equalTo: centerXAnchor),
///             label.centerYAnchor.constraint(equalTo: centerYAnchor)
///         ])
///     }
/// }
/// ```
class CoreView: UIView {
    
    /// 지정 이니셜라이저.
    ///
    /// - Parameter frame: 뷰의 프레임
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupAttribute()
        setupConstraints()
	}

    /// 스토리보드/XIB를 통한 초기화 시 호출됩니다.
    ///
    /// - Parameter coder: 인터페이스 빌더에서 뷰를 디코딩하기 위한 객체
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupAttribute()
        setupConstraints()
    }
    
    /// **뷰 계층을 구성하는 메서드**
    ///
    /// 이 메서드에서 **서브뷰를 추가(addSubview)** 합니다.
    /// 기본 구현은 비어 있으며, 서브클래스에서 오버라이드하여 사용합니다.
    func setupHierarchy() {}

    /// **뷰 속성을 설정하는 메서드**
    ///
    /// 이 메서드에서 색상, 텍스트, 폰트 등 시각적 속성을 지정합니다.
    /// 기본 구현에서는 배경색을 흰색으로 설정합니다.
    func setupAttribute() { backgroundColor = .white }
    
    /// **Auto Layout 제약 조건을 설정하는 메서드**
    ///
    /// 이 메서드에서 ``NSLayoutConstraint`` 또는 SnapKit 등을 사용하여 레이아웃을 정의합니다.
    /// 기본 구현은 비어 있으며, 서브클래스에서 오버라이드하여 사용합니다.
    func setupConstraints() {}
}
