//
//  HealthTabBarController.swift
//  Health
//
//  Created by 김건우 on 7/31/25.
//

import UIKit

final class HealthTabBarController: UITabBarController {

    private let tabHeight: CGFloat = 94

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        configureTabBarAppearance()
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()

        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .secondarySystemBackground

        appearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)

        appearance.stackedLayoutAppearance.selected.iconColor = .label
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)

        self.tabBar.standardAppearance = appearance
        self.tabBar.scrollEdgeAppearance = appearance
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.tabBar.frame.size.height = tabHeight
        self.tabBar.frame.origin.y = view.frame.height - tabHeight
    }
}

extension HealthTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let nav = viewController as? UINavigationController,
           let calendarVC = nav.viewControllers.first as? CalendarViewController {
            /// 캘린더 탭이 선택된 경우 현재 월로 스크롤하도록 설정
            calendarVC.shouldScrollToCurrentOnAppear = true
        }
    }
}
