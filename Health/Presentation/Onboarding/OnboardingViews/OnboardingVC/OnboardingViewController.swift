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
        button.setTitleColor(.white, for: .normal)
        button.applyCornerStyle(.medium)
        button.isEnabled = true
        return button
    }()
    
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
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    @objc private func continueButtonTapped() {
        performSegue(withIdentifier: "goToGenderInfo", sender: self)
    }
}
