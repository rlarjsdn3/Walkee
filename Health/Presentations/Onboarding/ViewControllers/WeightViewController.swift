//
//  WeightViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

class WeightViewController: CoreGradientViewController {
    
    // 제약
    @IBOutlet weak var weightInputField: DynamicWidthTextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var kgLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabelTopConst: NSLayoutConstraint!
    
    @IBOutlet weak var weightInputFieldCenterY: NSLayoutConstraint!
    private var originalCenterY: CGFloat = 0
    private var originalDescriptionTop: CGFloat = 0
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    private var weightInputFieldiPadWidthConstraint: NSLayoutConstraint?
    
    // 사용자 정보, 코어데이터 스택 선언
    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext
 
    private var shouldPerformSegueAfterKeyboardHide = false
    
    // 뷰 라이프 사이클
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        
        setupTextField()
        setupContinueButton()
        
        originalCenterY = weightInputFieldCenterY.constant
        originalDescriptionTop = descriptionLabelTopConst.constant
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        
        fetchUserInfo()
        if let weight = userInfo?.weight, weight > 0 {
            weightInputField.text = String(Int(weight))
            validateInput()
        } else {
            disableContinueButton()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if weightInputField.text?.isEmpty ?? true {
            weightInputField.becomeFirstResponder()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateTraitsConstraints()
        updateDescriptionTopConstraint()
        updateWeightInputFieldConstraints() // iPad/iPhone 대응
    }
    
    // 텍스트 필드 설정
    private func setupTextField() {
        weightInputField.delegate = self
        weightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        errorLabel.isHidden = true
        errorLabel.textColor = .red
    }
    
    // 다음 버튼 설정
    private func setupContinueButton() {
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
            self?.continueButton.alpha = (button.state == .highlighted) ? 0.75 : 1.0
        }
        continueButton.configuration = config
        continueButton.applyCornerStyle(.medium)
    }
    
    // 설명 레이블 탑 제약 아이패드 대응
    private func updateDescriptionTopConstraint() {
        // iPad 여부
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        let isLandscape = view.bounds.width > view.bounds.height

        if isIpad {
            // 아이패드 고정값 지정
            descriptionLabelTopConst.constant = isLandscape ? 28 : 80
        } else {
            // 아이폰은 세로모드만 사용 → 스토리보드 제약 그대로 사용
            descriptionLabelTopConst.constant = originalDescriptionTop
        }
    }

    // 화면 요소 아이폰, 아이패드 대응 코드
    private func updateTraitsConstraints() {
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        if isIpad {
            continueButtonLeading?.isActive = false
            continueButtonTrailing?.isActive = false
            if iPadWidthConstraint == nil {
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
                iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                iPadWidthConstraint?.isActive = true
                iPadCenterXConstraint?.isActive = true
            }
        } else {
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false
            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
        }
    }
    
    // 몸무게 입력 텍스트 필드 아이패드 대응
    private func updateWeightInputFieldConstraints() {
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            // iPad → 고정 width
            if weightInputFieldiPadWidthConstraint == nil {
                weightInputFieldiPadWidthConstraint = weightInputField.widthAnchor.constraint(equalToConstant: 120)
                weightInputFieldiPadWidthConstraint?.isActive = true
            }
        } else {
            // iPhone → dynamic width 사용
            weightInputFieldiPadWidthConstraint?.isActive = false
            weightInputFieldiPadWidthConstraint = nil
        }
    }
    
    // 키보드 노티피케이션
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide(_:)),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        let isLandscape = view.bounds.width > view.bounds.height
        let isIphonePortrait = !isIpad && !isLandscape
        
        if (isIpad && isLandscape) || isIphonePortrait {
            weightInputFieldCenterY.constant = originalCenterY - keyboardFrame.height * 0.5
        }
        continueButtonBottomConstraint?.constant = -(keyboardFrame.height + 20)
        
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        weightInputFieldCenterY.constant = originalCenterY
        continueButtonBottomConstraint?.constant = 0
        
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        if shouldPerformSegueAfterKeyboardHide {
            shouldPerformSegueAfterKeyboardHide = false
            performSegue(withIdentifier: "goToHeightInfo", sender: nil)
        }
    }
    
    // 화면 탭시 키보드 내려가는 매서드
    private func setupTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 버튼 액션 및 데이터 저장
    @IBAction func continueButtonTapped(_ sender: UIButton) {
        guard continueButton.isEnabled else { return }
        guard let text = weightInputField.text, let weightValue = Double(text) else { return }
        
        userInfo?.weight = weightValue
        try? context.save()
        
        if weightInputField.isFirstResponder {
            shouldPerformSegueAfterKeyboardHide = true
            view.endEditing(true)
        } else {
            performSegue(withIdentifier: "goToHeightInfo", sender: nil)
        }
    }
    
    // 텍스트필드 변동사항
    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
        textField.invalidateIntrinsicContentSize()
    }
    
    private func validateInput() {
        guard let text = weightInputField.text, !text.isEmpty else {
            disableContinueButton()
            hideError()
            return
        }

        if text.count == 1, text.hasPrefix("0") {
            disableContinueButton()
            weightInputField.text = ""
            return
        }
        
        if let weight = Int(text) {
            switch text.count {
            case 1: disableContinueButton(); hideError()
            case 2,3:
                if (30...200).contains(weight) { enableContinueButton(); hideError() }
                else { disableContinueButton(); showError() }
            default: disableContinueButton(); showError()
            }
        } else { disableContinueButton(); showError() }
    }

    private func showError(text: String = "30 ~ 200 사이의 값을 입력해주세요.") {
        errorLabel.isHidden = false
        errorLabel.text = text
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = ""
    }
    
    // 버튼 비활성화
    private func disableContinueButton() {
        continueButton.isEnabled = false
        continueButton.backgroundColor = .buttonBackground
        weightInputField.textColor = .label
    }
    
    // 버튼 활성화
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        weightInputField.textColor = .accent
    }
    
    // 사용자 정보 패치
    private func fetchUserInfo() {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            if let firstUserInfo = results.first {
                userInfo = firstUserInfo
            } else {
                let newUserInfo = UserInfoEntity(context: context)
                newUserInfo.id = UUID()
                newUserInfo.createdAt = Date()
                userInfo = newUserInfo
                try context.save()
            }
        } catch {
            print("UserInfo fetch error: \(error)")
        }
    }
}

extension WeightViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil { return false }
        
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return prospectiveText.count <= 3
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension WeightViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: continueButton) == true { return false }
        return true
    }
}

