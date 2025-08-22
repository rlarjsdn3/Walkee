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
    @IBOutlet weak var stepGoalLeading: NSLayoutConstraint!
    @IBOutlet weak var stepGoalTrailing: NSLayoutConstraint!
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    private var stepGoalViewWidthConstraint: NSLayoutConstraint?
    
    private let healthService = DefaultHealthService()
    
    @Injected private var stepSyncService: StepSyncService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        continueButton.applyCornerStyle(.medium)
        continueButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)

        stepGoalView.onValueChanged = { [weak self] _ in
            self?.updateContinueButtonState()
        }

        stepGoalView.value = 0
        updateContinueButtonState()
        
        if let parentVC = parent as? ProgressContainerViewController {
            parentVC.customNavigationBar.backButton.isHidden = true
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                      traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            continueButtonLeading?.isActive = false
            continueButtonTrailing?.isActive = false
            
            if iPadWidthConstraint == nil {
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
                iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                iPadWidthConstraint?.isActive = true
                iPadCenterXConstraint?.isActive = true
            }
            stepGoalLeading?.isActive = false
            stepGoalTrailing?.isActive = false
            
            if stepGoalViewWidthConstraint == nil {
                stepGoalViewWidthConstraint = stepGoalView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.93)
                stepGoalViewWidthConstraint?.isActive = true
            }
        } else {
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false
            
            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
            
            stepGoalViewWidthConstraint?.isActive = false
            stepGoalLeading?.isActive = true
            stepGoalTrailing?.isActive = true
        }
    }
    
    @objc private func updateContinueButtonState() {
        let isValid = stepGoalView.value > 0
        var config = UIButton.Configuration.filled()
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.preferredFont(forTextStyle: .headline)
            return out
        }
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .systemBackground
        var container = AttributeContainer()
        container.font = UIFont.preferredFont(forTextStyle: .headline)
        config.attributedTitle = AttributedString("다음", attributes: container)
            
        continueButton.configurationUpdateHandler = { [weak self] button in
            switch button.state
            {
            case .highlighted:
                self?.continueButton.alpha = 0.75
            default: self?.continueButton.alpha = 1.0
            }
        }
        continueButton.configuration = config
        continueButton.isEnabled = isValid
        continueButton.backgroundColor = isValid ? .accent : .buttonBackground
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        guard stepGoalView.value > 0 else { return }
        
        let context = CoreDataStack.shared.viewContext
        let today = Date().startOfDay()
        
        let fetchRequest: NSFetchRequest<GoalStepCountEntity> = GoalStepCountEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "effectiveDate == %@", today as NSDate)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            let goal: GoalStepCountEntity
            
            if let existing = results.first {
                goal = existing
                print("기존 목표 걸음 수 불러옴: \(goal.goalStepCount)")
            } else {
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

        UserDefaultsWrapper.shared.hasSeenOnboarding = true

        Task {
            do {
                try await stepSyncService.syncSteps()
                print("온보딩 직후 동기화 완료")
            } catch {
                print("온보딩 직후 동기화 실패: \(error.localizedDescription)")
            }
        }

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
