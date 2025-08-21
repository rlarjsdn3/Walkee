//
//  HealthLinkViewController.swift
//  Health
//
//  Created by 권도현 on 8/5/25.
//

import CoreData
import HealthKit
import UIKit

class HealthLinkViewController: CoreGradientViewController, Alertable {
    
    @IBOutlet weak var userDescriptionLabel: UILabel!
    @IBOutlet weak var healthAppIcon: UIImageView!
    @IBOutlet weak var linkedSwitch: UISwitch!
    @IBOutlet weak var supUserDescriptionLabel: UILabel!
    @IBOutlet weak var linkSettingView: UIView!
    @IBOutlet weak var linkSettingHeight: NSLayoutConstraint!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    
    @IBOutlet weak var appleLogo: UIImageView!
    @IBOutlet weak var appleLogoLeading: NSLayoutConstraint!
    @IBOutlet weak var linkSwitchTrailing: NSLayoutConstraint!
    
    @IBOutlet weak var linkSettingLeading: NSLayoutConstraint!
    @IBOutlet weak var linkSettingTrailing: NSLayoutConstraint!
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
    private var iPadLinkWidthConstraint: NSLayoutConstraint?
    private var iPadLinkCenterXConstraint: NSLayoutConstraint?
    
    private var originalLinkHeight: CGFloat = 0
    private var originalAppleLogoLeading: CGFloat = 0
    private var originalLinkSwitchTrailing: CGFloat = 0
    
    private let healthService = DefaultHealthService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        continueButton.setTitle("다음", for: .normal)
        continueButton.applyCornerStyle(.medium)
        continueButton.addTarget(self, action: #selector(continueButtonTapped(_:)), for: .touchUpInside)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        healthAppIcon.image = UIImage(systemName: "heart.fill")
        appleLogo.image = UIImage(systemName: "applelogo")
        
        originalLinkHeight = linkSettingHeight.constant
        originalAppleLogoLeading = appleLogoLeading.constant
        originalLinkSwitchTrailing = linkSwitchTrailing.constant
        
        setupAttribute()
        checkHealthKitPermissionStatus()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            continueButtonLeading?.isActive = false
            continueButtonTrailing?.isActive = false
     
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false
            iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
            iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            iPadWidthConstraint?.isActive = true
            iPadCenterXConstraint?.isActive = true

            linkSettingLeading?.isActive = false
            linkSettingTrailing?.isActive = false
            iPadLinkWidthConstraint?.isActive = false
            iPadLinkCenterXConstraint?.isActive = false
            iPadLinkWidthConstraint = linkSettingView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
            iPadLinkCenterXConstraint = linkSettingView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            iPadLinkWidthConstraint?.isActive = true
            iPadLinkCenterXConstraint?.isActive = true
            
            linkSettingHeight.constant = originalLinkHeight * 1.2
            appleLogoLeading.constant = originalAppleLogoLeading * 1.6
            linkSwitchTrailing.constant = originalLinkSwitchTrailing * 1.6
            
            linkSettingView.applyCornerStyle(.custom(24))
            
        } else {
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false
            iPadLinkWidthConstraint?.isActive = false
            iPadLinkCenterXConstraint?.isActive = false
      
            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
            linkSettingLeading?.isActive = true
            linkSettingTrailing?.isActive = true
            
            linkSettingHeight.constant = originalLinkHeight
            appleLogoLeading.constant = originalAppleLogoLeading
            linkSwitchTrailing.constant = originalLinkSwitchTrailing
            
            linkSettingView.applyCornerStyle(.medium)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func setupAttribute() {
        userDescriptionLabel.text = "사용자 데이터 입력 및 \n건강 앱 정보 가져오기 권한 설정"
        supUserDescriptionLabel.text = """
신체 측정값을 가져와서 걸음 수를 Apple 건강 앱과 지속적으로 동기화 할 수 있습니다.
"""
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
                        showAlert("권한 부족",
                                  message: "건강 앱 권한이 변경되어 연동이 해제되었습니다. 설정에서 다시 권한을 허용해주세요.") { _ in }
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
                    linkedSwitch.isOn = true
                    UserDefaultsWrapper.shared.hasSeenOnboarding = true
                } else {
                    linkedSwitch.isOn = false
                    UserDefaultsWrapper.shared.hasSeenOnboarding = false
                    showAlert("권한 부족",
                              message: "모든 권한을 허용해야 연동이 가능합니다. 설정 화면에서 권한을 다시 설정해주세요.",
                              onPrimaryAction: { _ in self.openAppSettings() })
                }
            }
        } catch {
            await MainActor.run {
                linkedSwitch.isOn = false
                UserDefaultsWrapper.shared.hasSeenOnboarding = false
                showAlert("오류", message: "HealthKit 권한 요청 중 오류가 발생했습니다.\n\(error.localizedDescription)") { _ in }
            }
        }
    }
    
    @IBAction private func continueButtonTapped(_ sender: Any) {
        if linkedSwitch.isOn {
            performSegue(withIdentifier: "goToGenderInfo", sender: nil)
        } else {
            showAlert(
                "건강 연동 필요",
                message: """
건강 연동을 해야 이용할 수 있는 서비스가 포함되어 있습니다.그래도 연동하지 않으시겠습니까?
""",
                onPrimaryAction: { _ in
                    Task {
                        await self.requestHealthKitAuthorization()
                    }
                },
                onCancelAction: { _ in
                    self.performSegue(withIdentifier: "goToGenderInfo", sender: nil)
                }
            )
        }
    }


    @IBAction private func linkAction(_ sender: UISwitch) {
        if sender.isOn {
            Task {
                await requestHealthKitAuthorization()
            }
        } else {
            UserDefaultsWrapper.shared.hasSeenOnboarding = false
            showAlert("연동 해제", message: "Apple 건강 앱 연동이 해제되었습니다.") { _ in }
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
