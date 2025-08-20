//
//  HealthNavigationBarDelegate.swift
//  Health
//
//  Created by 김건우 on 8/20/25.
//

import UIKit

/// 내비게이션 바의 동작을 위임하기 위한 프로토콜입니다.
@MainActor
protocol HealthNavigationBarDelegate: AnyObject {

    /// 뒤로 가기 버튼이 눌렸을 때 호출됩니다.
    /// - Parameter button: 사용자가 탭한 뒤로 가기 버튼
    func navigationBar(didTapBackButton button: UIButton)
}

extension HealthNavigationBarDelegate where Self: UIViewController {

    func navigationBar(didTapBackButton button: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
