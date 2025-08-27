//
//  ProfileViewController.swift
//  Health
//
//  Created by 하재준 on 8/1/25.
//

import UIKit
import TSAlertController
import MessageUI
import LocalAuthentication

struct ProfileCellModel {
    let title: String
    let iconName: String
    let isSwitch: Bool
    var switchState: Bool = UserDefaultsWrapper.shared.healthkitLinked
}

class ProfileViewController: HealthNavigationController, Alertable {
    
    @IBOutlet weak var tableView: UITableView!
    
    @Injected private var syncStepService: StepSyncService
    @Injected private var healthService: HealthService
    @Injected(.dailyStepViewModel) private var dailyStepVM: DailyStepViewModel
    @Injected(.goalStepCountViewModel) private var goalStepCountVM: GoalStepCountViewModel
    
    private var currentGoalCache: Int = 0
    
    private var isAuthenticating = false
    
    private let sectionTitles: [String?] = [
        nil,
        "개인 설정",
        "권한 설정",
        "기타"
    ]
    
    private var sectionItems: [[ProfileCellModel]] = [
        [
            ProfileCellModel(
                title: "신체 정보",
                iconName: "person.fill",
                isSwitch: false
            )
        ],
        [
            ProfileCellModel(
                title: "목표 걸음 설정",
                iconName: "figure.walk",
                isSwitch: false
            )
        ],
        [
            ProfileCellModel(
                title: "Apple 건강 앱",
                iconName: "applelogo",
                isSwitch: true,
                switchState: UserDefaultsWrapper.shared.healthkitLinked
            )
        ],
        [
            ProfileCellModel(
                title: "문의하기",
                iconName: "envelope.fill",
                isSwitch: false
            )
        ]
    ]
    
    override func setupAttribute() {
        super.setupAttribute()
        
        applyBackgroundGradient(.midnightBlack)
        
        healthNavigationBar.title = "프로필"
        healthNavigationBar.titleImage = UIImage(systemName: "person.crop.square.fill")
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "profileCell")
        tableView.rowHeight = 68
        tableView.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let latest = goalStepCountVM.goalStepCount(for: Date()).map(Int.init) ?? 0
        currentGoalCache = latest
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startForegroundGrantSync()
    }
    
    /// 앱이 포어그라운드로 복귀할 때마다 HealthKit 권한을 재확인하도록 옵저버를 등록합니다.
    ///
    /// - Important: Swift 6 기준 `MainActor` 격리를 위해 클로저 내부에서 `Task { @MainActor in ... }`로 hop 합니다.
    @MainActor
    private func startForegroundGrantSync() {
        
        NotificationCenter.default.addObserver(
            forName: .didChangeHKSharingAuthorizationStatus,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.recheckGrantAndSave()
            }
        }
    }
    
    
    /// 현재 HealthKit 읽기 권한을 비동기로 재확인하고, UI/모델/저장을 동기화합니다.
    @MainActor
    private func recheckGrantAndSave() async {
        print(#function, #line)
        let hasAny = await healthService.checkHasAnyReadPermission()
        UserDefaultsWrapper.shared.healthkitLinked = hasAny
        updateSectionItemsForHealthSwitch(to: hasAny)
        tableView.reloadData()
    }
    
    // MARK: - UserDefaults는 쓸지안쓸지 아직모르겠음
    @objc private func switchChanged(_ sender: UISwitch) {
        Task {
            if sender.isOn {
                // OFF -> ON
                let hasAny = try await healthService.requestAuthorization()
                await MainActor.run {
                    if hasAny {
                        // 하나라도 권한이 있으면 alert 없이 ON
                        UserDefaultsWrapper.shared.healthkitLinked = true
                        updateSectionItemsForHealthSwitch(to: true)
                    } else {
                        // 권한이 하나도 없으면 설정 유도 alert
                        sender.setOn(false, animated: true) // 일단 원복
                        presentGrantAlert(for: sender)
                    }
                }
                
                try? await syncStepService.syncSteps()
            } else {
                // ON -> OFF: 알럿 없이 바로 반영
                UserDefaultsWrapper.shared.healthkitLinked = false
                updateSectionItemsForHealthSwitch(to: false)
            }
            
            // 건강 앱 연동 스위치 상태가 변경되었음을 알림
            // healthkitLinked 값이 완전히 바뀐 후에 Notification 신호를 날립니다.
            NotificationCenter.default.post(
                name: .didChangeHealthLinkStatusOnProfile,
                object: nil,
                userInfo: [.status: sender.isOn]
            )
        }
    }
    
    private func startGrantRecheckAfterReturning(switch sender: UISwitch) {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.recheckGrantAndSyncSwitch(sender)
            }
        }
    }
    
    @MainActor
    private func recheckGrantAndSyncSwitch(_ sender: UISwitch) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let hasAny = await self.healthService.checkHasAnyReadPermission()
            
            // 권한이 하나라도 남아있으면 ON, 아니면 OFF 유지
            if hasAny {
                sender.setOn(true, animated: true)
                UserDefaultsWrapper.shared.healthkitLinked = true
                self.updateSectionItemsForHealthSwitch(to: true)
            } else {
                sender.setOn(false, animated: true)
                UserDefaultsWrapper.shared.healthkitLinked = false
                self.updateSectionItemsForHealthSwitch(to: false)
            }
        }
    }
    
    @MainActor
    private func presentGrantAlert(for sender: UISwitch) {
        showAlert(
            "권한 설정 필요",
            message: """
                     앱이 접근할 수 있는 건강 데이터가 없습니다.\n\n아래 경로에서 앱의 건강 데이터 접근 권한을 해제하거나 다시 활성화할 수 있습니다.\n\n 프로필(우측 상단) ⏵ 개인정보 보호 ⏵ 앱 ⏵ Walkee
                     """,
            primaryTitle: "열기",
            onPrimaryAction: ({ [weak self] _ in
                guard let self else { return }
                self.openHealthApp()
                self.startGrantRecheckAfterReturning(switch: sender)
            }),
            onCancelAction: ({ [weak self] _ in
                guard let self else { return }
                
                sender.setOn(false, animated: true)
                UserDefaultsWrapper.shared.healthkitLinked = false
                self.updateSectionItemsForHealthSwitch(to: false)
            })
        )
    }
    
    /// 건강(Health) 앱을 엽니다.
    ///
    /// - Note: 사용자가 Health 앱에서 권한을 직접 변경할 수 있도록 유도합니다.
    private func openHealthApp() {
        let healthURL = URL(string: "x-apple-health://")!
        UIApplication.shared.open(healthURL, options: [:])
    }
    
    private func updateSectionItemsForHealthSwitch(to newValue: Bool) {
        for section in sectionItems.indices {
            for row in sectionItems[section].indices where sectionItems[section][row].isSwitch {
                sectionItems[section][row].switchState = newValue
            }
        }
    }
}

extension ProfileViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath)
        let model = sectionItems[indexPath.section][indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: model.iconName)
        content.text = model.title
        content.imageProperties.tintColor = .systemGray
        
        cell.contentConfiguration = content
        cell.backgroundColor = UIColor.buttonText.withAlphaComponent(0.1)
        
        let bgView = UIView()
        bgView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.2)
        cell.selectedBackgroundView = bgView
        cell.selectionStyle = .default
        
        if model.isSwitch {
            let toggle = UISwitch(frame: .zero)
            toggle.isOn = model.switchState
            toggle.tag = indexPath.section
            toggle.onTintColor = .accent
            toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        } else if model.title == "목표 걸음 설정" {
            cell.accessoryView = nil
            cell.accessoryType = .none
            cell.selectionStyle = .default
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
}

extension ProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = sectionItems[indexPath.section][indexPath.row]
        
        switch model.title {
        case "신체 정보":
            guard !isAuthenticating else { return }
            isAuthenticating = true
            tableView.isUserInteractionEnabled = false
            
            let context = LAContext()
            context.localizedFallbackTitle = ""
            var error: NSError?
            
            let policy: LAPolicy = .deviceOwnerAuthentication
            
            guard context.canEvaluatePolicy(policy, error: &error) else {
                isAuthenticating = false
                tableView.isUserInteractionEnabled = true
                showWarningToast(
                    title: "인증 불가",
                    message: "이 기기에서 인증을 사용할 수 없습니다. 설정에서 Face ID/암호를 설정하세요."
                )
                return
            }
            
            context.evaluatePolicy(policy, localizedReason: "신체 정보에 접근하려면 인증이 필요합니다.") { [weak self] success, evalError in
                Task { @MainActor in
                    guard let self else { return }
                    self.isAuthenticating = false
                    tableView.isUserInteractionEnabled = true
                    
                    if success {
                        self.performSegue(withIdentifier: "bodyInfo", sender: nil)
                        return
                    }
                    
                    if let laError = evalError as? LAError {
                        switch laError.code {
                        case .appCancel, .systemCancel, .userCancel, .userFallback:
                            return
                        default:
                            break
                        }
                    }
                }
            }
            
        case "목표 걸음 설정":
            let goalStep = goalStepCountVM.goalStepCount(for: Date()).map(Int.init) ?? 0
            currentGoalCache = goalStep
            showActionSheetForProfile(
                buildView: {
                    let v = EditStepGoalView()
                    v.value = goalStep
                    return v
                },
                onConfirm: { [weak self] view in
                    guard let self, let v = view as? EditStepGoalView else { return }
                    
                    self.dailyStepVM.upsertDailyStep(goalStepCount: v.value)
                    self.goalStepCountVM.saveGoalStepCount(goalStepCount: Int32(v.value), effectiveDate: Date())
                    self.currentGoalCache = v.value
                    
                    NotificationCenter.default.post(name: .didUpdateGoalStepCount, object: nil)
                }
            )
        case "문의하기":
            if MFMailComposeViewController.canSendMail() {
                let vc = MFMailComposeViewController()
                vc.mailComposeDelegate = self
                
                var currentAppVersion: String {
                    guard let dictionary = Bundle.main.infoDictionary,
                          let version = dictionary["CFBundleShortVersionString"] as? String else { return "" }
                    return version
                }
                
                let bodyString =
                                         """
                                         이곳에 내용을 작성해 주세요.
                                         
                                         ================================
                                         Device Model : \(UIDevice.current.model)
                                         Device OS : \(UIDevice.current.systemVersion)
                                         App Version: \(currentAppVersion)
                                         ================================
                                         """
                vc.setToRecipients(["rlarjsdn3@naver.com"])
                vc.setSubject("문의 사항")
                vc.setMessageBody(bodyString, isHTML: false)
                
                self.present(vc, animated: true)
            } else {
                let alertController = TSAlertController(
                    title: "메일 계정 활성화가 필요합니다.",
                    message: "Mail 앱에서 사용자의 Email을 계정을 설정해 주세요.",
                    options: [
                        .dismissOnSwipeDown,
                        .dismissOnTapOutside,
                        .interactiveScaleAndDrag
                    ],
                    preferredStyle: .alert
                )
                
                let action = TSAlertAction(title: "확인", style: .default) { _ in
                    guard let mailSettingsURL = URL(string: UIApplication.openSettingsURLString + "&&path=MAIL") else { return }
                    
                    if UIApplication.shared.canOpenURL(mailSettingsURL) {
                        UIApplication.shared.open(mailSettingsURL, options: [:], completionHandler: nil)
                    }
                }
                action.configuration.backgroundColor = .accent
                action.configuration.titleAttributes = [
                    .font: UIFont.preferredFont(forTextStyle: .headline),
                    .foregroundColor: UIColor.systemBackground
                ]
                action.highlightType = .fadeIn
                
                alertController.addAction(action)
                
                self.present(alertController, animated: true)
            }
        default:
            break
        }
    }
}

extension ProfileViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        switch result {
        case .cancelled:
            showToast(message: "메일 작성을 취소했습니다.")
        case .saved:
            showToast(message: "메일을 임시 저장했습니다.")
        case .sent:
            showToast(message: "메일 전송을 완료 했습니다.")
        case .failed:
            showWarningToast(title: "전송 실패", message: "메일 전송에 실패했습니다.")
        @unknown default:
            break
        }
        
        self.dismiss(animated: true)
    }
}
