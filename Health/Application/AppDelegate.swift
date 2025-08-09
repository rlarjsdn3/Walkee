//
//  AppDelegate.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

/*
 coredata framework는 아래있는 더미데이터 테스트 코드 활성화일때만 켜주세요
 */

import UIKit
//import CoreData
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
		// MARK: - NetworkMonitor 싱글톤 인스턴스를 생성하고 모니터링 시작
		Task {
			await NetworkMonitor.shared.startMonitoring()
		}

        // TODO: - 앱 성능 테스트 관련 작업 시작할 때 주석 해제하기
		//FirebaseApp.configure()

        DIContainer.shared.registerAllServices()
        
        CoreDataStack.shared.insertDummyData()

        /* dummydata test code
         
        let context = CoreDataStack.shared.viewContext
            let fetchRequest: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
            
            do {
                let users = try context.fetch(fetchRequest)
                print("=== UserInfoEntity 개수: \(users.count) ===")
                for user in users {
                    let name = user.username ?? "Unknown"
                    let age = user.age
                    let diseases = user.diseases?.map { $0.rawValue }.joined(separator: ", ") ?? "None"
                    print("User: \(name), Age: \(age), Diseases: \(diseases)")
                }
            } catch {
                print("Failed to fetch UserInfoEntity: \(error.localizedDescription)")
            }
         */
            
            return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
    }


}

