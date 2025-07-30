//
//  CoreViewController.swift
//  Health
//
//  Created by juks86 on 7/30/25.
//

import UIKit

/// 공통 UI 구성 로직을 담당하는 기반 뷰 컨트롤러입니다.
///
/// 이 클래스를 상속하여 화면마다 공통적인 UI 계층 구성, 속성 설정,
/// 제약 조건 설정 등의 작업을 일관되게 구현할 수 있습니다.
class CoreViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        initVM()
        setupHierarchy()
        setupAttribute()
        setupConstraints()
    }

    /// ViewModel을 초기화하거나 바인딩하는 메서드입니다.
    ///
    /// 화면과 데이터 간의 연결을 설정할 때 활용되며,
    /// 구체적인 로직은 서브클래스에서 구현하시면 됩니다.
    func initVM() {
    }

    /// 뷰 계층 구조를 구성하는 메서드입니다.
    ///
    /// 서브뷰를 `self.view` 또는 다른 컨테이너 뷰에 추가하는 역할을 합니다.
    func setupHierarchy() {
    }

    /// 각 뷰의 속성을 설정하는 메서드입니다.
    ///
    /// 예를 들어 텍스트, 색상, 폰트 등의 시각적 속성을 지정할 때 사용됩니다.
    func setupAttribute() {
    }

    /// 뷰의 Auto Layout 제약 조건을 설정하는 메서드입니다.
    ///
    /// `NSLayoutConstraint` 등의 도구를 사용하여
    /// 뷰의 레이아웃을 정의할 때 활용됩니다.
    func setupConstraints() {
    }
}
