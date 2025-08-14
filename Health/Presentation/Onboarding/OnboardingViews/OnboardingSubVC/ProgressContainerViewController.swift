//  ProgressContainerViewController.swift
//  Health
//
//  Created by 권도현 on 8/13/25.
//

// ProgressContainerViewController.swift

import UIKit
import CoreData

@MainActor
protocol OnboardingStepValidatable: AnyObject {
    func isStepInputValid() -> Bool
}

class ProgressContainerViewController: CoreGradientViewController {

    public func setBackButtonHidden(_ isHidden: Bool) {
        customNavigationBar.backButton.isHidden = isHidden
    }
    
    public func setBackButtonEnabled(_ isEnabled: Bool) {
        customNavigationBar.backButton.isEnabled = isEnabled
        customNavigationBar.backButton.alpha = isEnabled ? 1.0 : 0.5
    }
    
    let customNavigationBar = CustomNavigationBarView(totalPages: 7)
    private var currentChildVC: UINavigationController?
    
    private var currentStep: Int = 1
    private let totalSteps: Int = 7
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .boxBg
        
        setupCustomNavigationBar()
        
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let firstVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
        setChildViewController(firstVC)
        
        updateProgressForCurrentStep()
    }
    
    private func setupCustomNavigationBar() {
        view.addSubview(customNavigationBar)
        customNavigationBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customNavigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavigationBar.heightAnchor.constraint(equalToConstant: 60)
        ])
        customNavigationBar.delegate = self
    }

    func setChildViewController(_ vc: UIViewController) {
        if let currentChildVC = currentChildVC {
            currentChildVC.willMove(toParent: nil)
            currentChildVC.view.removeFromSuperview()
            currentChildVC.removeFromParent()
        }

        let navController: UINavigationController
        if let nav = vc as? UINavigationController {
            navController = nav
        } else {
            navController = UINavigationController(rootViewController: vc)
        }
        
        navController.delegate = self
        
        addChild(navController)
        navController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navController.view)
        navController.navigationController?.view.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            navController.view.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor),
            navController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        navController.didMove(toParent: self)
        currentChildVC = navController
    }
    
    private func updateProgressForCurrentStep() {
        let progress = min(CGFloat(currentStep) / CGFloat(totalSteps), 1)
        customNavigationBar.progressIndicatorStackView.updateProgress(to: progress)
    }
}

extension ProgressContainerViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.hidesBackButton = true
        viewController.navigationItem.leftBarButtonItem = nil
        
        if let index = navigationController.viewControllers.firstIndex(of: viewController) {
            currentStep = min(index + 1, totalSteps)
            updateProgressForCurrentStep()
            
            // 첫 번째 뷰 컨트롤러는 뒤로가기 버튼을 숨김
            if index == 0 {
                setBackButtonHidden(true)
                setBackButtonEnabled(false)
            } else {
                setBackButtonHidden(false)

                if let validatableVC = viewController as? OnboardingStepValidatable {

                    setBackButtonEnabled(validatableVC.isStepInputValid())
                } else {
                    // 프로토콜을 준수하지 않는 뷰 컨트롤러는 기본적으로 활성화
                    setBackButtonEnabled(true)
                }
            }
        }
    }
}

extension ProgressContainerViewController: @preconcurrency CustomNavigationBarViewDelegate {
    @MainActor
    func backButtonTapped() {
        guard let nav = currentChildVC else { return }
        if nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            currentStep = max(currentStep - 1, 1)
            updateProgressForCurrentStep()
        }
    }
}
