//
//  StepGoalViewController.swift
//  Health
//
//  Created by 권도현 on 8/19/25.
//

import UIKit
import CoreData
import HealthKit

class StepGoalViewController: CoreGradientViewController {
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var stepGoalView: EditStepGoalView!
    @IBOutlet weak var stepViewDescription: UILabel!
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    private let healthService = DefaultHealthService()
    
    @Injected private var stepSyncService: StepSyncService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        continueButton.applyCornerStyle(.medium)
        continueButton.isEnabled = true
        continueButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        
        if let parentVC = parent as? ProgressContainerViewController {
            parentVC.customNavigationBar.backButton.isHidden = true
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
        traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            continueButtonLeading?.isActive = false
            continueButtonTrailing?.isActive = false
            
            if iPadWidthConstraint == nil {
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
                iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                iPadWidthConstraint?.isActive = true
                iPadCenterXConstraint?.isActive = true
            }
        } else {
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false
            
            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
        }
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        let context = CoreDataStack.shared.viewContext
        let today = Date().startOfDay()
      
        let fetchRequest: NSFetchRequest<GoalStepCountEntity> = GoalStepCountEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "effectiveDate == %@", today as NSDate)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            let goal: GoalStepCountEntity
            
            if let existing = results.first {
                // 이미 저장된 값 사용
                goal = existing
                print("기존 목표 걸음 수 불러옴: \(goal.goalStepCount)")
            } else {
                // 새로 생성
                goal = GoalStepCountEntity(context: context)
                goal.id = UUID()
                goal.effectiveDate = today
                goal.goalStepCount = Int32(stepGoalView.value)
                print("새 목표 걸음 수 저장: \(goal.goalStepCount)")
            }
            
            try context.save()
            
        } catch {
            print("목표 걸음 수 저장/불러오기 실패: \(error.localizedDescription)")
        }
        
        // 온보딩 완료 플래그
        UserDefaultsWrapper.shared.hasSeenOnboarding = true
        
        // 걸음 수 데이터 동기화
        Task {
            do {
                try await stepSyncService.syncSteps()
                print("온보딩 직후 동기화 완료")
            } catch {
                print("온보딩 직후 동기화 실패: \(error.localizedDescription)")
            }
        }
        
        // RootViewController 전환
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let tabBarController = storyboard.instantiateInitialViewController() as? UITabBarController else {
                print("Main.storyboard 초기 VC가 UITabBarController가 아님")
                return
            }
            
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
            UIView.transition(with: window,
                              duration: 0.5,
                              options: [.transitionCrossDissolve],
                              animations: nil)
        }
    }
}
