//
//  OnboardingViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit

class OnboardingViewController: CoreGradientViewController {
    
    @IBOutlet weak var appImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.accent
        button.setTitleColor(.label, for: .normal)
        button.applyCornerStyle(.medium)
        button.isEnabled = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return button
    }()

    private var continueButtonLeading: NSLayoutConstraint!
    private var continueButtonTrailing: NSLayoutConstraint!

    private var iPadLeadingConstraint: NSLayoutConstraint?
    private var iPadTrailingConstraint: NSLayoutConstraint?
    
    override func initVM() {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        
        appImageView.image = UIImage(named: "appIconAny")
        appImageView.contentMode = .scaleAspectFit
        appImageView.applyCornerStyle(.medium)
        appImageView.clipsToBounds = true
        
        titleLabel.text = "환영합니다!"
        descriptionLabel.text = "사용자에게 더 정확한 운동측정과 맞춤 추천을 제공하기 위해 사용자 입력 정보가 필요합니다."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.alpha = 0.7
        
        if let parentVC = parent as? ProgressContainerViewController {
            parentVC.customNavigationBar.backButton.isHidden = true
        }
    }
    
    override func setupHierarchy() {
        [continueButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    override func setupConstraints() {
        // iPhone 기본 margin
        continueButtonLeading = continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        continueButtonTrailing = continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButtonLeading,
            continueButtonTrailing,
            continueButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                      traitCollection.verticalSizeClass == .regular
        
        guard let parentVC = parent as? ProgressContainerViewController else { return }
        
        if isIpad {
            continueButtonLeading.isActive = false
            continueButtonTrailing.isActive = false
            
            iPadLeadingConstraint = continueButton.leadingAnchor.constraint(equalTo: parentVC.customNavigationBar.leadingAnchor)
            iPadTrailingConstraint = continueButton.trailingAnchor.constraint(equalTo: parentVC.customNavigationBar.trailingAnchor)
            iPadLeadingConstraint?.isActive = true
            iPadTrailingConstraint?.isActive = true
            
        } else {
            iPadLeadingConstraint?.isActive = false
            iPadTrailingConstraint?.isActive = false
            continueButtonLeading.isActive = true
            continueButtonTrailing.isActive = true
        }
        
        view.layoutIfNeeded()
    }
    
    @objc private func continueButtonTapped() {
        performSegue(withIdentifier: "goToHealthLink", sender: self)
    }
}

