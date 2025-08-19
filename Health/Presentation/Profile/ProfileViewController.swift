//
//  ProfileViewController.swift
//  Health
//
//  Created by 하재준 on 8/1/25.
//

import UIKit
import TSAlertController
import MessageUI

struct ProfileCellModel {
    let title: String
    let iconName: String
    let isSwitch: Bool
    var switchState: Bool = UserDefaultsWrapper.shared.healthkitLinked
}

class ProfileViewController: CoreGradientViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @Injected private var healthService: HealthService
    @Injected(.goalStepCountViewModel) private var goalVM: GoalStepCountViewModel
    
    private var currentGoalCache: Int = 0
    
    private var grantRecheckObserver: NSObjectProtocol?
    
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
            ),
            ProfileCellModel(
                title: "화면 모드 설정",
                iconName: "iphone.motion",
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
        
        navigationItem.title = "프로필"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "profileCell")
        tableView.rowHeight = 68
        tableView.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startForegroundGrantSync()
        let latest = goalVM.goalStepCount(for: Date()).map(Int.init) ?? 0
        currentGoalCache = latest
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopForegroundGrantSync()
    }
    
    deinit {
        stopForegroundGrantSync()
    }
    
    /// 앱이 포어그라운드로 복귀할 때마다 HealthKit 권한을 재확인하도록 옵저버를 등록합니다.
    ///
    /// - Important: Swift 6 기준 `MainActor` 격리를 위해 클로저 내부에서 `Task { @MainActor in ... }`로 hop 합니다.
    @MainActor
    private func startForegroundGrantSync() {
        stopForegroundGrantSync()
        
        grantRecheckObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.recheckGrantAndSave()
            }
        }
    }
    
    /// 포어그라운드 권한 확인하는 옵저버를 제거합니다.
    ///
    /// - Note: 옵저버가 중복 등록되지 않도록 옵저버를 등록하기 전에 호출합니다.
    private func stopForegroundGrantSync() {
        if let obs = grantRecheckObserver {
            NotificationCenter.default.removeObserver(obs)
            grantRecheckObserver = nil
        }
    }
    
    /// 현재 HealthKit 읽기 권한을 비동기로 재확인하고, UI/모델/저장을 동기화합니다.
    @MainActor
    private func recheckGrantAndSave() async {
        let hasAny = await healthService.checkHasAnyReadPermission()
        UserDefaultsWrapper.shared.healthkitLinked = hasAny
        updateSectionItemsForHealthSwitch(to: hasAny)
    }
    
    /// 테이블 셀 내 스위치 값 변경 이벤트를 처리합니다.
    ///
    /// - Parameter sender: `UISwitch`
    @objc private func switchChanged(_ sender: UISwitch) {
        // ON: 권한 요청
        if sender.isOn {
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let granted = try await self.healthService.requestAuthorization()
                    await MainActor.run {
                        if granted {
                            // 정상적으로 하나 이상 허용됨
                            UserDefaultsWrapper.shared.healthkitLinked = true
                            self.updateSectionItemsForHealthSwitch(to: true)
                        } else {
                            // 권한이 하나도 없을 때: 권한 허용 얼럿 표시
                            self.presentGrantAlert(for: sender)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.presentGrantAlert(for: sender)
                    }
                }
            }
        } else { // OFF
            presentDenyAlert(for: sender)
        }
    }
    
    private func startGrantRecheckAfterReturning(switch sender: UISwitch) {
        // 기존 옵저버 제거
        if let obs = grantRecheckObserver {
            NotificationCenter.default.removeObserver(obs)
            grantRecheckObserver = nil
        }
        
        grantRecheckObserver = NotificationCenter.default.addObserver(
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
        if let obs = grantRecheckObserver {
            NotificationCenter.default.removeObserver(obs)
            grantRecheckObserver = nil
        }
        
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
        let alert = TSAlertController(
            title: "권한 설정 안내",
            message:
                """
                건강 앱에서 권한을 직접 바꿀 수 있어요.
                경로: 프로필(우측 상단) > 개인정보보호 > 앱 > Health
                여기에서 이 앱의 데이터 접근 권한을 해제하거나 다시 켤 수 있습니다.
                """,
            preferredStyle: .alert
        )
        alert.viewConfiguration.titleAlignment = .center
        alert.viewConfiguration.messageAlignment = .center
        alert.viewConfiguration.size.width = .proportional(minimumRatio: 0.9)
        
        // 취소: 사용자가 거부 의사 → OFF
        alert.addAction(TSAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            sender.setOn(false, animated: true)
            UserDefaultsWrapper.shared.healthkitLinked = false
            self.updateSectionItemsForHealthSwitch(to: false)
        })
        // 열기: 건강앱 열어주고 돌아오면 권한 재확인
        let action = TSAlertAction(title: "열기", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.openHealthApp()
            self.startGrantRecheckAfterReturning(switch: sender)
        }
        
        action.configuration.backgroundColor = .accent
        action.configuration.titleAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline),
            .foregroundColor: UIColor.systemBackground
        ]
        action.highlightType = .fadeIn
        alert.addAction(action)
        
        present(alert, animated: true)
    }
    
    private func presentDenyAlert(for sender: UISwitch) {
        let alert = TSAlertController(
            title: "권한 설정 안내",
            message:
                """
                건강 앱에서 권한을 직접 바꿀 수 있어요.
                경로: 프로필(우측 상단) > 개인정보보호 > 앱 > Health
                여기에서 이 앱의 데이터 접근 권한을 해제하거나 다시 켤 수 있습니다.
                """,
            preferredStyle: .alert
        )
        alert.viewConfiguration.titleAlignment = .center
        alert.viewConfiguration.messageAlignment = .center
        alert.viewConfiguration.size.width = .proportional(minimumRatio: 0.9)
        alert.addAction(TSAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            // 취소: 스위치 복구
            sender.setOn(true, animated: true)
            UserDefaultsWrapper.shared.healthkitLinked = true
            self.updateSectionItemsForHealthSwitch(to: true)
        })
        let action = TSAlertAction(title: "열기", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // 건강 앱 열기
            self.openHealthApp()
            
            // 설정에서 돌아오면 권한을 재확인해 스위치 상태 동기화
            self.startGrantRecheckAfterReturning(switch: sender)
        }
        action.configuration.backgroundColor = .accent
        action.configuration.titleAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline),
            .foregroundColor: UIColor.systemBackground
        ]
        action.highlightType = .fadeIn
        alert.addAction(action)
        present(alert, animated: true)
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
        } else if model.title == "목표 걸음 설정" || model.title == "화면 모드 설정" {
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
            performSegue(withIdentifier: "bodyInfo", sender: nil)
        case "목표 걸음 설정":
            let goalStep = goalVM.goalStepCount(for: Date()).map(Int.init) ?? 0
            currentGoalCache = goalStep
            print("goalstep:\(goalStep)")
            
            presentSheet(on: self,
                         buildView: {
                let v = EditStepGoalView()
                v.value = goalStep
                v.step = 500
                v.minValue = 0
                v.maxValue = 100_000
                return v
            }) { [weak self] view in
                guard let self, let v = view as? EditStepGoalView else { return }
                self.goalVM.saveGoalStepCount(goalStepCount: Int32(v.value), effectiveDate: Date())
                self.currentGoalCache = v.value
                print(v.value)
            }
        case "화면 모드 설정":
            presentSheet(on: self) {
                let v = DisplayModeView()
                return v
            }
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
                let alertController = TSAlertController(title: "메일 계정 활성화가 필요합니다.", message: "Mail 앱에서 사용자의 Email을 계정을 설정해 주세요.", preferredStyle: .alert)
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
            showToast(message: "작성 취소")
        case .saved:
            showToast(message: "임시 저장")
        case .sent:
            showToast(message: "메일 전송 완료")
        case .failed:
            showWarningToast(title: "전송 실패", message: "메일 전송에 실패했습니다.")
        @unknown default:
            break
        }
        
        self.dismiss(animated: true)
    }
}
