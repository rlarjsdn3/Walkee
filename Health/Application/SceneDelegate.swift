//
//  SceneDelegate.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    @Injected var stepSyncViewModel: StepSyncViewModel

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        window?.rootViewController = setupRootViewController(hasCompletedOnboarding: hasCompletedOnboarding)
        window?.makeKeyAndVisible()
        
    }

    private func setupRootViewController(hasCompletedOnboarding: Bool) -> UIViewController {
        if hasCompletedOnboarding {
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

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    	// TODO: 건강 앱 연동 후 HealthKit 걸음 데이터 동기화 작업시 주석 해제
//        Task {
//             await stepSyncViewModel.syncDailySteps()
//        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
