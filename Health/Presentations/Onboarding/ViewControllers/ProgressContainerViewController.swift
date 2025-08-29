//  ProgressContainerViewController.swift
//  Health
//
//  Created by 권도현 on 8/13/25.
//

// ProgressContainerViewController.swift

import UIKit
import CoreData

class ProgressContainerViewController: CoreGradientViewController {

    // 뒤로가기 버튼 비활성화
    public func setBackButtonHidden(_ isHidden: Bool) {
        customNavigationBar.backButton.isHidden = isHidden
    }
    
    // 뒤로가기 버튼 활성화
    public func setBackButtonEnabled(_ isEnabled: Bool) {
        customNavigationBar.backButton.isEnabled = isEnabled
        customNavigationBar.backButton.alpha = isEnabled ? 1.0 : 0.5
    }
    
    // 커스텀 네비게이션 바 선언
    let customNavigationBar = CustomNavigationBarView(totalPages: 8)
    private var currentChildVC: UINavigationController?
    
    private var currentStep: Int = 1
    private let totalSteps: Int = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .boxBg
        
        setupCustomNavigationBar()
        
        // 온보딩 뷰컨 두번 불러오는 원인 !! 절대 주석 풀지 말것!!!
//        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
//        let firstVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
//        setChildViewController(firstVC)
        
        updateProgressForCurrentStep()
    }
    
    // 네비게이션 바 설정
    private func setupCustomNavigationBar() {
        view.addSubview(customNavigationBar)
        customNavigationBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customNavigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavigationBar.heightAnchor.constraint(equalToConstant: 50)
        ])
        customNavigationBar.delegate = self
    }

    // childVC 설정 매서드
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
    
    // 네비게이션 바 게이지 업데이트 매서드 
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

            if index == 0 {
                setBackButtonHidden(true)
            } else {
                setBackButtonHidden(false)
                setBackButtonEnabled(true)
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
