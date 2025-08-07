//
//  OnboardingViewController 2.swift
//  Health
//
//  Created by 권도현 on 8/7/25.
//


import UIKit

class DiseaseViewController: CoreViewController {
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.accent
        button.setTitleColor(.white, for: .normal)
        button.applyCornerStyle(.medium)
        button.isEnabled = true
        return button
    }()
    
    private let progressIndicatorStackView = ProgressIndicatorStackView(totalPages: 4)
    
    override func initVM() {}
    
    override func viewDidLoad() {
          super.viewDidLoad()
          continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        let backBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
           navigationItem.backBarButtonItem = backBarButton
      }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressIndicatorStackView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressIndicatorStackView.isHidden = true
    }
    
    override func setupHierarchy() {
        [continueButton, progressIndicatorStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    override func setupAttribute() {
        progressIndicatorStackView.updateProgress(to: 0.125)
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48),
            
            progressIndicatorStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 78),
            progressIndicatorStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressIndicatorStackView.heightAnchor.constraint(equalToConstant: 4),
            progressIndicatorStackView.widthAnchor.constraint(equalToConstant: 320)
        ])
    }
    
    @objc private func continueButtonTapped() {
        performSegue(withIdentifier: "goToHealthLink", sender: self)
    }
}
