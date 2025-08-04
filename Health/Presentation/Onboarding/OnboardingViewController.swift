//
//  OnboardingViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit

class OnboardingViewController: CoreViewController {
    
    @IBOutlet weak var appImageView: UIImageView!
    
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
        button.layer.cornerRadius = 10
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
    
    override func initVM() {
        // ViewModel 초기화 필요 시 구현
    }
    
    override func viewDidLoad() {
          super.viewDidLoad()
          continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
      }
    
    override func setupHierarchy() {
        [descriptionLabel, continueButton, pageIndicatorStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    override func setupAttribute() {
        setupPageIndicators(currentPage: 0)
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: appImageView.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 48),
            
            pageIndicatorStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 78),
            pageIndicatorStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicatorStack.heightAnchor.constraint(equalToConstant: 4),
            pageIndicatorStack.widthAnchor.constraint(equalToConstant: 320)
        ])
    }
    
    private func setupPageIndicators(currentPage: Int) {
        pageIndicatorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for i in 0..<4 {
            let bar = UIView()
            bar.backgroundColor = (i <= currentPage) ? .accent : .buttonBackground
            pageIndicatorStack.addArrangedSubview(bar)
        }
    }
    
    @objc private func continueButtonTapped() {
        performSegue(withIdentifier: "goToGenderInfo", sender: self)
    }
}
