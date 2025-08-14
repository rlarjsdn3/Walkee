//
//  HealthLinkViewController.swift
//  Health
//
//  Created by 권도현 on 8/5/25.
//

import UIKit
import HealthKit

class HealthLinkViewController: CoreGradientViewController {
    
    @IBOutlet weak var userDescriptionLabel: UILabel!
    @IBOutlet weak var healthAppIcon: UIImageView!
    @IBOutlet weak var linkedSwitch: UISwitch!
    @IBOutlet weak var supUserDescriptionLabel: UILabel!
    @IBOutlet weak var linkSettingView: UIView!
    
    private let healthService = DefaultHealthService()
    private let userDefaultsKeys = UserDefaultsKeys()
    
    @IBAction func linkAction(_ sender: UISwitch) {
        if sender.isOn {
            Task {
                await requestHealthKitAuthorization()
            }
        } else {
            sender.isOn = false
            UserDefaults.standard.set(false, forKey: userDefaultsKeys.hasSeenOnboarding.name)
            showAlert(title: "연동 해제됨", message: "Apple 건강 앱과의 연동이 해제되었습니다.")
        }
    }
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.accent
        button.setTitleColor(.white, for: .normal)
        button.applyCornerStyle(.medium)
        return button
    }()
    
    private let progressIndicatorStackView = ProgressIndicatorStackView(totalPages: 4)
    
    override func initVM() {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        checkHealthKitPermissionStatus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressIndicatorStackView.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func setupHierarchy() {
        [continueButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    override func setupAttribute() {
        healthAppIcon.image = UIImage(systemName: "heart.fill")
        
        userDescriptionLabel.text = "사용자 데이터 입력 및 \n건강 앱 정보 가져오기 권한 설정"
        
        supUserDescriptionLabel.text = "신체 측정값을 가져와서 걸음 수를 Apple 건강 앱과\n 지속적으로 동기화 할 수 있습니다."
        supUserDescriptionLabel.alpha = 0.5
        
        linkSettingView.backgroundColor = UIColor(named: "boxBgColor")
        linkSettingView.applyCornerStyle(.medium)
        linkSettingView.clipsToBounds = true
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    @objc private func handleAppWillEnterForeground() {
        checkHealthKitPermissionStatus()
    }
    
    private func checkHealthKitPermissionStatus() {
        Task {
            let hasAnyPermission = await healthService.checkHasAnyReadPermission()
            
            await MainActor.run {
                let storedLinked = UserDefaults.standard.bool(forKey: userDefaultsKeys.hasSeenOnboarding.name)
                
                if hasAnyPermission {
                    linkedSwitch.isOn = true
                    UserDefaults.standard.set(true, forKey: userDefaultsKeys.hasSeenOnboarding.name)
                } else {
                    linkedSwitch.isOn = false
                    
                    if storedLinked {
                        showAlert(title: "권한 부족", message: "건강 앱 권한이 변경되어 연동이 해제되었습니다. 설정에서 다시 권한을 허용해주세요.")
                        UserDefaults.standard.set(false, forKey: userDefaultsKeys.hasSeenOnboarding.name)
                    }
                }
            }
        }
    }
    
    private func requestHealthKitAuthorization() async {
        do {
            let granted = try await healthService.requestAuthorization()
            
            await MainActor.run {
                if granted {
                    showAlert(title: "연동 완료", message: "Apple 건강 앱과의 연동이 완료되었습니다.")
                    linkedSwitch.isOn = true
                    UserDefaults.standard.set(true, forKey: userDefaultsKeys.hasSeenOnboarding.name)
                } else {
                    linkedSwitch.isOn = false
                    UserDefaults.standard.set(false, forKey: userDefaultsKeys.hasSeenOnboarding.name)
                    showAlert(title: "권한 부족", message: "모든 권한을 허용해야 연동이 가능합니다. 설정 화면에서 권한을 다시 설정해주세요.") {
                        self.openAppSettings()
                    }
                }
            }
        } catch {
            await MainActor.run {
                linkedSwitch.isOn = false
                UserDefaults.standard.set(false, forKey: userDefaultsKeys.hasSeenOnboarding.name)
                showAlert(title: "오류", message: "HealthKit 권한 요청 중 오류가 발생했습니다.\n\(error.localizedDescription)")
            }
        }
    }
    
    @objc private func continueButtonTapped() {
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
                              animations: nil)
        }
        UserDefaults.standard.set(true, forKey: userDefaultsKeys.hasSeenOnboarding.name)
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

extension HealthLinkViewController {
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
}
