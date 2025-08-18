//
//  HealthLinkViewController.swift
//  Health
//
//  Created by 권도현 on 8/5/25.
//

import CoreData
import HealthKit
import UIKit

class HealthLinkViewController: CoreGradientViewController {
    
    @IBOutlet weak var userDescriptionLabel: UILabel!
    @IBOutlet weak var healthAppIcon: UIImageView!
    @IBOutlet weak var linkedSwitch: UISwitch!
    @IBOutlet weak var supUserDescriptionLabel: UILabel!
    @IBOutlet weak var linkSettingView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
    private let healthService = DefaultHealthService()
    private let progressIndicatorStackView = ProgressIndicatorStackView(totalPages: 4)
    
    override func initVM() {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        continueButton.setTitle("다음", for: .normal)
        continueButton.backgroundColor = UIColor.accent
        continueButton.setTitleColor(.label, for: .normal)
        continueButton.applyCornerStyle(.medium)
        
        continueButton.addTarget(self, action: #selector(continueButtonTapped(_:)), for: .touchUpInside)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        checkHealthKitPermissionStatus()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            // iPhone 제약 비활성화
            continueButtonLeading?.isActive = false
            continueButtonTrailing?.isActive = false
            
            if iPadWidthConstraint == nil {
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
                iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                iPadWidthConstraint?.isActive = true
                iPadCenterXConstraint?.isActive = true
            }
        } else {
            // iPad 제약 비활성화
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false
            
            // iPhone 제약 활성화
            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressIndicatorStackView.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    @objc private func handleAppWillEnterForeground() {
        checkHealthKitPermissionStatus()
    }
    
    private func checkHealthKitPermissionStatus() {
        Task {
            let hasAnyPermission = await healthService.checkHasAnyReadPermission()
            await MainActor.run {
                let storedLinked = UserDefaultsWrapper.shared.hasSeenOnboarding
                if hasAnyPermission {
                    linkedSwitch.isOn = true
                    UserDefaultsWrapper.shared.hasSeenOnboarding = true
                } else {
                    linkedSwitch.isOn = false
                    if storedLinked {
                        showAlert(title: "권한 부족", message: "건강 앱 권한이 변경되어 연동이 해제되었습니다. 설정에서 다시 권한을 허용해주세요.")
                        UserDefaultsWrapper.shared.hasSeenOnboarding = false
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
                    UserDefaultsWrapper.shared.hasSeenOnboarding = true
                } else {
                    linkedSwitch.isOn = false
                    UserDefaultsWrapper.shared.hasSeenOnboarding = false
                    showAlert(title: "권한 부족",
                              message: "모든 권한을 허용해야 연동이 가능합니다. 설정 화면에서 권한을 다시 설정해주세요.") {
                        self.openAppSettings()
                    }
                }
            }
        } catch {
            await MainActor.run {
                linkedSwitch.isOn = false
                UserDefaultsWrapper.shared.hasSeenOnboarding = false
                showAlert(title: "오류", message: "HealthKit 권한 요청 중 오류가 발생했습니다.\n\(error.localizedDescription)")
            }
        }
    }
    
    @IBAction private func continueButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "goToGenderInfo", sender: nil)
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

