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
    @IBOutlet weak var descriptionTopConst: NSLayoutConstraint!
    
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
    
    private var originalDescriptionTop: CGFloat = 0
    private var originalLinkHeight: CGFloat = 0
    private var originalAppleLogoLeading: CGFloat = 0
    private var originalLinkSwitchTrailing: CGFloat = 0
    
    private let healthService = DefaultHealthService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        originalDescriptionTop = descriptionTopConst.constant
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        var config = UIButton.Configuration.filled()
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.preferredFont(forTextStyle: .headline)
            return out
        }
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .systemBackground
        var container = AttributeContainer()
        container.font = UIFont.preferredFont(forTextStyle: .headline)
        config.attributedTitle = AttributedString("다음", attributes: container)
            
        continueButton.configurationUpdateHandler = { [weak self] button in
            switch button.state
            {
            case .highlighted:
                self?.continueButton.alpha = 0.75
            default: self?.continueButton.alpha = 1.0
            }
        }
        
        
        continueButton.configuration = config
        continueButton.applyCornerStyle(.medium)
        continueButton.addTarget(self, action: #selector(continueButtonTapped(_:)), for: .touchUpInside)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        healthAppIcon.image = UIImage(named: "HealthAppIcon")
        appleLogo.image = UIImage(systemName: "applelogo")
        
        originalLinkHeight = linkSettingHeight.constant
        originalAppleLogoLeading = appleLogoLeading.constant
        originalLinkSwitchTrailing = linkSwitchTrailing.constant
        
        setupAttribute()
        checkHealthKitPermissionStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
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
        
        updateDescriptionTopConstraint()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func setupAttribute() {
        userDescriptionLabel.text = "사용자 데이터 입력 및 \n건강 앱 정보 가져오기 권한 설정"
        supUserDescriptionLabel.text = "신체 측정값을 가져와서 걸음 수를 Apple 건강 앱과 지속적으로 동기화 할 수 있습니다."
        linkSettingView.backgroundColor = UIColor(named: "boxBgColor")
        linkSettingView.applyCornerStyle(.medium)
        linkSettingView.clipsToBounds = true
    }
    
    @objc private func handleAppWillEnterForeground() {
        checkHealthKitPermissionStatus()
    }
    
    private func updateDescriptionTopConstraint() {
        // iPad 여부
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        let isLandscape = view.bounds.width > view.bounds.height

        if isIpad {
            // 아이패드 고정값 지정
            descriptionTopConst.constant = isLandscape ? 28 : 80
        } else {
            // 아이폰은 세로모드만 사용 → 스토리보드 제약 그대로 사용
            descriptionTopConst.constant = originalDescriptionTop
        }
    }
    
    private func checkHealthKitPermissionStatus() {
        Task {
            let hasAnyPermission = await healthService.checkHasAnyReadPermission()
            await MainActor.run {
                if hasAnyPermission {
                    linkedSwitch.isOn = true
                    UserDefaultsWrapper.shared.healthkitLinked = true
                } else {
                    linkedSwitch.isOn = false
                    UserDefaultsWrapper.shared.healthkitLinked = false
                }
            }
        }
    }
    
    private func openHealthApp() {
        let healthURL = URL(string: "x-apple-health://")!
        UIApplication.shared.open(healthURL, options: [:])
    }
    
    /*
     
    - 사용자가 건강 권한을 받는 시트에서 모두 비허용 시, “건강 권한 비허용 시, 앱 사용에 지장을 줄 수 있다”는 경고와 함께 1️⃣설정 화면으로 이동할지 2️⃣계속 온보딩을 진행할지 묻는 알림창 띄우는 로직으로 변경
    
    - 사용자가 아무런 데이터를 허용하지 않고, 다시 스위치를 Off → On으로 변경 시, “설정 화면으로 이동해서 허용해야 한다”는 알림과 함께 1️⃣설정 화면으로 이동할지 2️⃣계속 온보딩을 진행할지 묻는 알림창 띄우기
     
     - 기존로직과 혼동하지말것 ⚠️
     */
    
    private func requestHealthKitAuthorization() async {
        do {
            let granted = try await healthService.requestAuthorization()
            await MainActor.run {
                if granted {
                    linkedSwitch.isOn = true
                    UserDefaultsWrapper.shared.healthkitLinked = true
                } else {
                    linkedSwitch.isOn = false
                    UserDefaultsWrapper.shared.healthkitLinked = false
                  
                    showAlert(
                        "권한 설정",
                        message: "건강앱 연동없이 앱 실행시, 일부기능이 제한될 수 있습니다. 건강 앱 화면으로 이동하시겠습니까?",
                        primaryTitle: "열기",
                        onPrimaryAction: { _ in
                            // 오후 회의 이후 어느경로로 이동하는지 정하는거로
//                            self.openAppSettings()
                            self.openHealthApp()
                        },
                        cancelTitle: "취소",
                        onCancelAction: { _ in
                        }
                    )
                }
            }
        } catch {
            await MainActor.run {
                linkedSwitch.isOn = false
                UserDefaultsWrapper.shared.healthkitLinked = false
                showAlert(
                    "오류",
                    message: "HealthKit 권한 요청 중 오류가 발생했습니다.\n\(error.localizedDescription)",
                    primaryTitle: "확인",
                    onPrimaryAction: { _ in },
                    onCancelAction: nil
                )
            }
        }
    }

    
    @IBAction private func continueButtonTapped(_ sender: Any) {
            performSegue(withIdentifier: "goToGenderInfo", sender: nil)
    }


    @IBAction private func linkAction(_ sender: UISwitch) {
        if sender.isOn {
            Task {
                await requestHealthKitAuthorization()
            }
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
