//
//  InputAgeViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

class InputAgeViewController: CoreGradientViewController {

    @IBOutlet weak var ageInputField: YearTextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var yearLabel: UILabel!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var descriptionLabelTopConst: NSLayoutConstraint!
    @IBOutlet weak var ageInputFieldCenterY: NSLayoutConstraint!
    private var ageInputFieldiPadWidthConstraint: NSLayoutConstraint?
    
    private var originalCenterY: CGFloat = 0
    private var originalDescriptionTop: CGFloat = 0
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    private let keyboardButtonPadding: CGFloat = 20

    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext

    private var shouldPerformSegueAfterKeyboardHide = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupContinueButton()
        setupTextField()
        setupUIValues()
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        disableContinueButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if ageInputField.text?.isEmpty ?? true {
            ageInputField.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAndDisplayUserInfo()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContinueButtonConstraints()
        updateDescriptionTopConstraint()
        updateAgeInputFieldConstraints()
    }

    private func setupContinueButton() {
        applyBackgroundGradient(.midnightBlack)
        
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
    
    private func setupTextField() {
        ageInputField.delegate = self
        ageInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        errorLabel.isHidden = true
        errorLabel.textColor = .red
    }

    
    private func setupUIValues() {
        originalCenterY = ageInputFieldCenterY.constant
        originalDescriptionTop = descriptionLabelTopConst.constant
    }

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
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        let isLandscape = view.bounds.width > view.bounds.height
        let isIphonePortrait = !isIpad && !isLandscape
        
        if (isIpad && isLandscape) || isIphonePortrait {
            ageInputFieldCenterY.constant = originalCenterY - keyboardFrame.height * 0.5
        }
        
        continueButtonBottomConstraint.constant = -(keyboardFrame.height + keyboardButtonPadding)
        
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        ageInputFieldCenterY.constant = originalCenterY
        continueButtonBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        if shouldPerformSegueAfterKeyboardHide {
            shouldPerformSegueAfterKeyboardHide = false
            self.performSegue(withIdentifier: "goToWeightInfo", sender: nil)
        }
    }
    
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

    @IBAction func continueButtonTapped(_ sender: UIButton) {
        guard continueButton.isEnabled else { return }
        guard let text = ageInputField.text, let birthYear = Int16(text) else { return }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = Int16(currentYear - Int(birthYear))
        userInfo?.age = age

        do {
            try context.save()
            print("저장된 나이: \(userInfo?.age ?? 0)")
        } catch {
            print("Failed to save user info: \(error)")
        }

        if ageInputField.isFirstResponder {
            shouldPerformSegueAfterKeyboardHide = true
            view.endEditing(true)
        } else {
            performSegue(withIdentifier: "goToWeightInfo", sender: nil)
        }
    }

    private func fetchAndDisplayUserInfo() {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            if let first = results.first {
                self.userInfo = first
                if first.age != 0 {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    let birthYear = currentYear - Int(first.age)
                    ageInputField.text = String(birthYear)
                    validateInput()
                } else {
                    ageInputField.text = ""
                    validateInput()
                }
            } else {
                let newUser = UserInfoEntity(context: context)
                newUser.id = UUID()
                newUser.createdAt = Date()
                self.userInfo = newUser
                ageInputField.text = ""
                validateInput()
                try context.save()
            }
        } catch {
            print("Failed to fetch or create user info: \(error)")
            ageInputField.text = ""
            validateInput()
        }
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
    }
    
    private func updateAgeInputFieldConstraints() {
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            // iPad → 고정 width
            if ageInputFieldiPadWidthConstraint == nil {
                ageInputFieldiPadWidthConstraint = ageInputField.widthAnchor.constraint(equalToConstant: 130)
                ageInputFieldiPadWidthConstraint?.isActive = true
            }
        } else {
            // iPhone → dynamic width 사용
            ageInputFieldiPadWidthConstraint?.isActive = false
            ageInputFieldiPadWidthConstraint = nil
        }
    }
    
    private func validateInput() {
        guard let text = ageInputField.text, !text.isEmpty else {
            disableContinueButton()
            hideError()
            return
        }

        if text.count == 1, text.hasPrefix("0") {
            disableContinueButton()
            ageInputField.text = ""
            return
        }
        
        if let year = Int(text) {
            switch text.count {
            case 1,2,3:
                disableContinueButton()
                hideError()
            case 4:
                if (1900...(Date.now.year - 1)).contains(year) {
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

    private func showError(text: String = "1900 ~ 2024 사이의 값을 입력해주세요.") {
        errorLabel.isHidden = false
        errorLabel.text = text
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = ""
    }
    
    private func disableContinueButton() {
        continueButton.isEnabled = false
        continueButton.backgroundColor = .buttonBackground
        ageInputField.textColor = .label
    }
    
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        ageInputField.textColor = .accent
    }

    private func updateContinueButtonConstraints() {
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            if iPadWidthConstraint == nil {
                continueButtonLeading.isActive = false
                continueButtonTrailing.isActive = false
                
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
                iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                
                iPadWidthConstraint?.isActive = true
                iPadCenterXConstraint?.isActive = true
            }
        } else {
            if let iPadWidthConstraint = iPadWidthConstraint, iPadWidthConstraint.isActive {
                iPadWidthConstraint.isActive = false
                iPadCenterXConstraint?.isActive = false
                continueButtonLeading.isActive = true
                continueButtonTrailing.isActive = true
            }
        }
    }
    
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

}

extension InputAgeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil { return false }
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return prospectiveText.count <= 4
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension InputAgeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton {
            return false
        }
        return true
    }
}
