//
//  HeightViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

class HeightViewController: CoreGradientViewController {
    
    //제약
    @IBOutlet weak var heightInputField: DynamicWidthTextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var cmLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabelTopConst: NSLayoutConstraint!
    
    @IBOutlet weak var heightInputFieldCenterY: NSLayoutConstraint!
    private var originalCenterY: CGFloat = 0
    private var originalDescriptionTop: CGFloat = 0
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    private var heightInputFieldiPadWidthConstraint: NSLayoutConstraint?
    
    // userInfo, coredataStack 선언
    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext
    
    private var shouldPerformSegueAfterKeyboardHide = false
    
    //뷰 라이프 사이클
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        
        setupTextField()
        setupContinueButton()
        
        originalCenterY = heightInputFieldCenterY.constant
        originalDescriptionTop = descriptionLabelTopConst.constant
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        
        fetchUserInfo()
        if let height = userInfo?.height, height > 0 {
            heightInputField.text = String(Int(height))
            validateInput()
        } else {
            disableContinueButton()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if heightInputField.text?.isEmpty ?? true {
            heightInputField.becomeFirstResponder()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateTraitsConstraints()
        updateDescriptionTopConstraint()
        updateHeightInputFieldConstraints()
    }
    
    // 텍스트 필드 설정
    private func setupTextField() {
        heightInputField.delegate = self
        heightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
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
    
    // 설명 레이블 탑 제약 업데이트 코드
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
    
    //키보드 노티피케이션 매서드 선언
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }
    
    // 텍스트필드 너비 제약 대응 코드
    private func updateHeightInputFieldConstraints() {
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            // iPad → 고정 width
            if heightInputFieldiPadWidthConstraint == nil {
                heightInputFieldiPadWidthConstraint = heightInputField.widthAnchor.constraint(equalToConstant: 120)
                heightInputFieldiPadWidthConstraint?.isActive = true
            }
        } else {
            // iPhone → dynamic width 사용
            heightInputFieldiPadWidthConstraint?.isActive = false
            heightInputFieldiPadWidthConstraint = nil
        }
    }
    
    //키보드 노티 매서드
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        let isLandscape = view.bounds.width > view.bounds.height
        let isIphonePortrait = !isIpad && !isLandscape
        
        if (isIpad && isLandscape) || isIphonePortrait {
            heightInputFieldCenterY.constant = originalCenterY - keyboardFrame.height * 0.5
        }
        
        continueButtonBottomConstraint?.constant = -(keyboardFrame.height + 20)
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        heightInputFieldCenterY.constant = originalCenterY
        continueButtonBottomConstraint?.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        if shouldPerformSegueAfterKeyboardHide {
            shouldPerformSegueAfterKeyboardHide = false
            performSegue(withIdentifier: "goToDiseaseTap", sender: nil)
        }
    }
    
    // 화면 탭 - 키보드 내리는 매서드
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
    
    // 액션 매서드
    @IBAction func continueButtonTapped(_ sender: UIButton) {
        guard continueButton.isEnabled else { return }
        guard let text = heightInputField.text, let heightValue = Double(text) else { return }
        
        userInfo?.height = heightValue
        try? context.save()
        
        if heightInputField.isFirstResponder {
            shouldPerformSegueAfterKeyboardHide = true
            view.endEditing(true)
        } else {
            performSegue(withIdentifier: "goToDiseaseTap", sender: nil)
        }
    }
    
    // 텍스트 필드 변동시 선언
    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
        textField.invalidateIntrinsicContentSize()
    }
    
    //입력값에 따라 버튼 활성화/비활성화 구분하는 switch문
    private func validateInput() {
        guard let text = heightInputField.text,
              !text.isEmpty else {
            disableContinueButton()
            hideError()
            return
        }

        if text.count == 1, text.hasPrefix("0") {
            disableContinueButton()
            heightInputField.text = ""
            return
        }
        
        if let height = Int(text) {
            switch text.count {
            case 1,2:
                disableContinueButton()
                hideError()
                
            case 3:
                if (100...230).contains(height) {
                    enableContinueButton()
                    hideError()
                } else {
                    disableContinueButton()
                    showError()
                }
                
            default:
                disableContinueButton()
                showError()
            }
        } else {
            disableContinueButton()
            showError()
        }
    }
    
    private func showError(text: String = "100 ~ 230 사이의 값을 입력해주세요.") {
        errorLabel.isHidden = false
        errorLabel.text = text
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = ""
    }
    
    //버튼 상태 매서드
    private func disableContinueButton() {
        continueButton.isEnabled = false
        continueButton.backgroundColor = .buttonBackground
        heightInputField.textColor = .label
    }
    
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        heightInputField.textColor = .accent
    }
    
    // 사용자 패치
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

extension HeightViewController: UITextFieldDelegate {
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

extension HeightViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: continueButton) == true { return false }
        return true
    }
}
