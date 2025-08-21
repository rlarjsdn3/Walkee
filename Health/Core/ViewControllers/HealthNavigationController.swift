//
//  HealthNavigationController.swift
//  Health
//
//  Created by 김건우 on 8/20/25.
//

import UIKit

class HealthNavigationController: CoreGradientViewController {

    let healthNavigationBar = HealthNavigationBar()
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        setupHealthNavigationBar()
    }
    
    /// 네비게이션 바를 뷰에 추가하고, 속성과 제약을 설정합니다.
    ///
    /// - Note: `CoreViewController`의 `setupHierachy()`, `setupAttributes()` 메서드에서
    ///   네비게이션 바 설정을 하지 않는 이유는 기존 코드와의 호환성을 유지하기 위함입니다.
    ///   해당 메서드에서 네비게이션 바를 설정하면 기존 모든 코드에서 `super` 메서드를
    ///   호출해야 하므로, 이를 피하기 위해 별도의 메서드로 분리했습니다.
    func setupHealthNavigationBar() {
        view.addSubview(healthNavigationBar)
        healthNavigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        let barHeight: CGFloat = 50
        NSLayoutConstraint.activate([
            healthNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            healthNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            healthNavigationBar.heightAnchor.constraint(equalToConstant: barHeight)
        ])
        
        
        let topConstraint = healthNavigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        topConstraint.constant = isPad ? -63 : -barHeight
        topConstraint.isActive = true
        
        additionalSafeAreaInsets.top = isPad ? 0 : barHeight
    }
}
