//
//  SceneDelegate.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    @Injected private var healthService: (any HealthService)
    @Injected private var stepSyncService: (any StepSyncService)
    
    private var hkSharingAutorizationStatus: Bool = false

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        initializeHKSharingAuthorizationStatus()
        let hasSeenOnboarding = UserDefaultsWrapper.shared.hasSeenOnboarding
        
        let savedTheme = DisplayModeView.loadSavedTheme()
        window?.overrideUserInterfaceStyle = savedTheme.uiStyle
        
        window?.rootViewController = setupRootViewController(hasSeenOnboarding: hasSeenOnboarding)
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        if UserDefaultsWrapper.shared.hasSeenOnboarding {
            syncSteps()
        }
        
        refreshHKSharingAuthorizationStatus()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}

private extension SceneDelegate {

    func setupRootViewController(hasSeenOnboarding: Bool) -> UIViewController {
        if hasSeenOnboarding {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateInitialViewController() else {
                fatalError("Main.storyboard 초기 뷰컨트롤러 없음")
            }
            return vc
        } else {
            let containerVC = ProgressContainerViewController()

            let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
            guard let navController = onboardingStoryboard.instantiateInitialViewController() as? UINavigationController else {
                fatalError("Onboarding.storyboard 초기 뷰컨트롤러가 UINavigationController가 아님")
            }
            guard navController.viewControllers.first is OnboardingViewController else {
                fatalError("UINavigationController 루트가 OnboardingViewController가 아님")
            }

            containerVC.setChildViewController(navController)

            return containerVC
        }
    }

    func syncSteps() {
        Task {
            do {
                try await stepSyncService.syncSteps()
            } catch {
                print("걸음 데이터 동기화 실패: \(error.localizedDescription)")
            }
        }
    }
}


fileprivate extension SceneDelegate {
    
    func initializeHKSharingAuthorizationStatus() {
        Task {
            hkSharingAutorizationStatus = await healthService.checkHasAnyReadPermission()
        }
    }
    
    func refreshHKSharingAuthorizationStatus() {
        Task {
            let refreshedHKSharingAuthorizationStatus = await healthService.checkHasAnyReadPermission()
            if hkSharingAutorizationStatus != refreshedHKSharingAuthorizationStatus {
                hkSharingAutorizationStatus = refreshedHKSharingAuthorizationStatus
                postHKSharingAuthorizationStatusDidChangeNotification(for: hkSharingAutorizationStatus)
            }
        }
    }
    
    func postHKSharingAuthorizationStatusDidChangeNotification(for status: Bool) {
        NotificationCenter.default.post(
            name: .didChangeHKSharingAuthorizationStatus,
            object: nil,
            userInfo: [.status: status]
        )
        print("🔊 Post HKSharingAuthorizationStatusdidChangeNotification - (status: \(status))")
    }
}
