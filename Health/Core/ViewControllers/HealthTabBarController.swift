//
//  HealthTabBarController.swift
//  Health
//
//  Created by 김건우 on 7/31/25.
//

import UIKit

final class HealthTabBarController: UITabBarController {

    private let tabHeight: CGFloat = 94

    private var previousSelectedIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        configureTabBarAppearance()
        setPreviousSelectedIndex(selectedIndex)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.tabBar.frame.size.height = tabHeight
        self.tabBar.frame.origin.y = view.frame.height - tabHeight
    }
}

private extension HealthTabBarController {

    func configureTabBarAppearance() {
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

    func setPreviousSelectedIndex(_ index: Int) {
        previousSelectedIndex = index
    }
}

extension HealthTabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let nav = viewController as? UINavigationController,
              let topVC = nav.viewControllers.first else { return }

        let currentSelectedIndex = selectedIndex

        // 같은 탭을 다시 탭한 경우 (이전 인덱스와 현재 인덱스가 같음)
        if previousSelectedIndex == currentSelectedIndex {
            // 뷰가 로드된 상태에서만 스크롤 동작 실행
            guard topVC.isViewLoaded else { return }

            if let scrollableVC = topVC as? ScrollableToTop {
                scrollableVC.scrollToTop()
            } else if let calendarVC = topVC as? CalendarViewController {
                calendarVC.scrollToCurrentMonth()
            }
        }

        // 현재 선택된 탭을 이전 탭으로 업데이트
        setPreviousSelectedIndex(currentSelectedIndex)
    }
}
