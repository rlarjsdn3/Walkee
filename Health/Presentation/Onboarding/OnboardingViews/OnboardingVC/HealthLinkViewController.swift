//
//  HealthLinkViewController.swift
//  Health
//
//  Created by 권도현 on 8/5/25.
//

import UIKit

class HealthLinkViewController: CoreViewController {
    
    @IBOutlet weak var userDescriptionLabel: UILabel!
    @IBOutlet weak var healthAppIcon: UIImageView!
    @IBOutlet weak var linkedSwitch: UISwitch!
    @IBOutlet weak var supUserDescriptionLabel: UILabel!
    @IBOutlet weak var linkSettingView: UIView!
    
    @IBAction func linkAction(_ sender: Any) {
       
    }
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.accent
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
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
        progressIndicatorStackView.updateProgress(to: 0.75)

        healthAppIcon.image = UIImage(systemName: "heart.fill")
        
        userDescriptionLabel.text = "사용자 데이터 입력 및 \n건강 앱 정보 가져오기 권한 설정"
        
        supUserDescriptionLabel.text = "신체 측정값을 가져와서 걸음 수를 Apple 건강 앱과 지속적으로\n 동기화 할 수 있습니다."
        supUserDescriptionLabel.alpha = 0.3

        linkSettingView.backgroundColor = UIColor(named: "boxBgColor")
        linkSettingView.applyCornerStyle(.medium)
        linkSettingView.clipsToBounds = true
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
        //main storyboard 로 이동할 로직 구현
    }
}
