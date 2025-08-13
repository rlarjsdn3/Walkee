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
        let storyboardName = hasCompletedOnboarding ? "Main" : "Onboarding"
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        
        guard let viewController = storyboard.instantiateInitialViewController() else {
            fatalError("\(storyboardName).storyboard 초기 뷰컨트롤러 없음")
        }
        
        return viewController
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

