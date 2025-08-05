//
//  OnboardingViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit

class OnboardingViewController: CoreViewController {
    
    @IBOutlet weak var appImageView: UIImageView!
    
    
    @IBAction func debugMode(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let tabBarController = storyboard.instantiateInitialViewController() as? UITabBarController else {
            print("Main.storyboard의 초기 뷰컨트롤러가 UITabBarController가 아닙니다.")
            return
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
            
            UIView.transition(with: window,
                              duration: 0.5,
                              options: [.transitionCrossDissolve],
                              animations: nil,
                              completion: nil)
        }
    }

    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "사용자에게 더 정확한 운동측정과 맞춤 추천을 제공하기 위해 사용자 입력 정보가 필요합니다."
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.accent
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.isEnabled = true
        return button
    }()
    
    private let pageIndicatorStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        return stack
    }()
    
    override func initVM() {}
    
    override func viewDidLoad() {
          super.viewDidLoad()
          continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        let backBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
           navigationItem.backBarButtonItem = backBarButton
      }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pageIndicatorStack.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pageIndicatorStack.isHidden = true
    }
    
    override func setupHierarchy() {
        [descriptionLabel, continueButton, pageIndicatorStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    override func setupAttribute() {
        setupPageIndicators(progress: 0.125)
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: appImageView.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48),
            
            pageIndicatorStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 78),
            pageIndicatorStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicatorStack.heightAnchor.constraint(equalToConstant: 4),
            pageIndicatorStack.widthAnchor.constraint(equalToConstant: 320)
        ])
    }
    
    private func setupPageIndicators(progress: CGFloat) {
        pageIndicatorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let totalPages = 4
        let clampedProgress = max(0, min(progress, 1))
        let totalProgress = CGFloat(totalPages) * clampedProgress

        for i in 0..<totalPages {
            let containerView = UIView()
            containerView.backgroundColor = .buttonBackground
            containerView.layer.cornerRadius = 2
            containerView.clipsToBounds = true

            let progressBar = UIView()
            progressBar.backgroundColor = .accent
            progressBar.translatesAutoresizingMaskIntoConstraints = false

            containerView.addSubview(progressBar)

            let fillRatio: CGFloat
            if totalProgress > CGFloat(i + 1) {
                fillRatio = 1.0
            } else if totalProgress > CGFloat(i) {
                fillRatio = totalProgress - CGFloat(i)
            } else {
                fillRatio = 0.0
            }

            NSLayoutConstraint.activate([
                progressBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                progressBar.topAnchor.constraint(equalTo: containerView.topAnchor),
                progressBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                progressBar.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: fillRatio)
            ])

            pageIndicatorStack.addArrangedSubview(containerView)

            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.heightAnchor.constraint(equalToConstant: 4).isActive = true
        }
    }

    
    @objc private func continueButtonTapped() {
        performSegue(withIdentifier: "goToGenderInfo", sender: self)
    }
}
