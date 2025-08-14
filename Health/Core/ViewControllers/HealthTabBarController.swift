//
//  HealthTabBarController.swift
//  Health
//
//  Created by 김건우 on 7/31/25.
//

import UIKit
import TSAlertController

final class HealthTabBarController: UITabBarController, Alertable {

    private let tabHeight: CGFloat = 94

    // 위치 권한 거부 알림을 이미 보여줬는지 기록하는 변수
    private var hasShownPermissionDeniedAlert = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBarAppearance()

        self.delegate = self
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

    // 권한이 거부되었을 때 설정 앱으로 안내하는 알림창 (한 번만)
    private func showLocationPermissionAlert() {
        // 이미 알림을 보여줬다면 다시 보여주지 않음
        guard !hasShownPermissionDeniedAlert else {
            return
        }

        // 알림을 보여줬다고 기록
        hasShownPermissionDeniedAlert = true

        // 커스텀 알림창 사용
        showAlert(
            "위치 권한 필요",
            message: "추천 코스 기능을 사용하려면 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해 주세요.",
            onPrimaryAction: { _ in
                // "확인" 버튼 눌렀을 때 → 설정 앱으로 이동
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            },
            onCancelAction: { _ in
                print("위치 권한 설정 취소됨")
            }
        )
    }
}

//MARK: - UITabBarControllerDelegate
// 탭바 선택 이벤트를 처리하는 확장
extension HealthTabBarController: UITabBarControllerDelegate {

    // 탭이 선택되기 전에 호출되는 함수
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        // 맞춤케어 탭이 선택되었는지 확인 (탭 인덱스로 확인)
        guard let selectedIndex = viewControllers?.firstIndex(of: viewController) else {
            return true // 인덱스를 찾을 수 없으면 그냥 허용
        }

        if selectedIndex == 2 {

            let locationManager = LocationPermissionManager()

            if locationManager.checkCurrentPermissionStatus() {
                print("위치 권한이 이미 있음 - 맞춤케어 탭으로 이동")
                return true
            }

            // 권한이 없다면 권한 요청
            Task { @MainActor in
                let granted = await locationManager.requestLocationPermission()

                if granted {
                    // 권한이 허용된 경우 - 맞춤케어 탭으로 이동
                    print("위치 권한 허용됨 - 맞춤케어 탭으로 이동")
                    self.selectedViewController = viewController

                } else {
                    // 권한이 거부된 경우 - 설정 안내 알림창 표시
                    print("위치 권한 거부됨 - 설정 앱으로 안내")
                    self.showLocationPermissionAlert()
                }
            }
            return true
        }
        // 다른 탭으로 자유롭게 이동 허용
        return true
    }
}
