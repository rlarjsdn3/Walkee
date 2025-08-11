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
        
        // UserDefaults에서 온보딩 완료 여부 확인
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        let storyboard: UIStoryboard
        let rootVC: UIViewController
        
        if hasCompletedOnboarding {
            // 온보딩 완료 → 메인 화면 (예: Main.storyboard 초기 VC)
            storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let mainVC = storyboard.instantiateInitialViewController() else {
                fatalError("Main.storyboard 초기 뷰컨트롤러 없음")
            }
            rootVC = mainVC
        } else {
            // 온보딩 미완료 → 온보딩 화면 (예: Onboarding.storyboard 초기 VC)
            storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            guard let onboardingVC = storyboard.instantiateInitialViewController() else {
                fatalError("Onboarding.storyboard 초기 뷰컨트롤러 없음")
            }
            rootVC = onboardingVC
        }
        
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
    }


    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
#if DEBUG
        print("앱 활성화됨 → 걸음 데이터 동기화")
#endif
        Task {
            await stepSyncViewModel.syncDailySteps()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}

