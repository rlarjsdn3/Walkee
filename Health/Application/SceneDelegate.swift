//
//  SceneDelegate.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    @Injected private var healthService: (any HealthService)
    @Injected private var stepSyncService: (any StepSyncService)
    
    private var hkSharingAutorizationStatus: Bool = false
	private var motionAgg: ForegroundMotionAggregator?
	
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
		print(SharedStore.suiteID)
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        initializeHKSharingAuthorizationStatus()
        let hasSeenOnboarding = UserDefaultsWrapper.shared.hasSeenOnboarding
        
        
        window?.rootViewController = setupRootViewController(hasSeenOnboarding: hasSeenOnboarding)
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }
	
	func sceneDidBecomeActive(_ scene: UIScene) {
		// TODO: 이상 없으면 삭제할 로그 - 앱 그룹 각자 설정한 ID 잘 들어가있는 체크하기 위한 임시 용도
		// App Group 컨테이너 확인
		let id  = SharedStore.suiteID
		let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
		print("📦 [APP] groupID=\(id), url=\(url?.path ?? "nil")")
		
		// 온보딩 이전엔 절대 HealthKit 권한 요청/접근 안 함
		guard UserDefaultsWrapper.shared.hasSeenOnboarding else {
			print("ℹ️ Onboarding not finished. Skip Health snapshot.")
			return
		}
		
		Task {
			if await healthService.checkHasAnyReadPermission() {
				await DashboardSnapshotStore.updateFromHealthKit()
				print("🟢 widget snapshot updated from HealthKit")
			} else {
				print("⚠️ Health permission not granted, skip snapshot")
			}
		}
	}

    func sceneWillResignActive(_ scene: UIScene) {
		motionAgg?.stop()
		motionAgg = nil
    }

	func sceneWillEnterForeground(_ scene: UIScene) {
		Task { @MainActor in
			// 마지막에 무조건 실행 (노티 전파는 연기) - 권한 관련 상태 갱신 위해서 있는 부분
			defer { refreshHKSharingAuthorizationStatus() }
			
			if UserDefaultsWrapper.shared.hasSeenOnboarding {
				syncSteps()
				
				if await healthService.checkHasAnyReadPermission() {
					await DashboardSnapshotStore.updateFromHealthKit()
					print("🟢 foreground snapshot updated")
				} else {
					print("⚠️ Health permission not granted (foreground), skip snapshot")
				}
			}
		}
		// TODO: 문제가 발생한 경우 기존 설정해뒀던 코드로 되돌리기 위한 임시 주석입니다.(이상이 없다면 바로 삭제 예정)
//		if UserDefaultsWrapper.shared.hasSeenOnboarding {
//			syncSteps()
//			Task {
//				if await healthService.checkHasAnyReadPermission() { // 상태 점검(팝업 없음)
//					await DashboardSnapshotStore.updateFromHealthKit()
//					print("🟢 foreground snapshot updated")
//				} else {
//					print("⚠️ Health permission not granted (foreground), skip snapshot")
//				}
//			}
//		}
//		
//        refreshHKSharingAuthorizationStatus()
		
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
				do {
					let snap = try await DefaultDashboardSnapshotProvider().makeSnapshot(for: .now)
					DashboardSnapshotStore.saveAndNotify(snap)
				} catch {
					print("🔴 Widget snapshot update failed:", error)
				}
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
