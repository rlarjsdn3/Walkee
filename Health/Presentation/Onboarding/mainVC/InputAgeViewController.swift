//
//  SelectAgeViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

class InputAgeViewController: CoreGradientViewController {

    @IBOutlet weak var ageInputField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var ageInputFieldCenterY: NSLayoutConstraint!
    private var originalCenterY: CGFloat = 0

    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    private let keyboardButtonPadding: CGFloat = 20

    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        
        ageInputField.delegate = self
        ageInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        errorLabel.isHidden = true
        errorLabel.textColor = .red
        continueButton.applyCornerStyle(.medium)
        
        originalCenterY = ageInputFieldCenterY.constant
        
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
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContinueButtonConstraints()
    }
    
    private func updateContinueButtonConstraints() {
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        
        if isIpad {
            if iPadWidthConstraint == nil {
                continueButtonLeading.isActive = false
                continueButtonTrailing.isActive = false
                
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
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
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        ageInputFieldCenterY.constant = originalCenterY
        continueButtonBottomConstraint.constant = -20
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    private func setupTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
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
        guard let text = ageInputField.text, let year = Int16(text) else { return }
        
        userInfo?.age = year
        do {
            try context.save()
            performSegue(withIdentifier: "goToWeightInfo", sender: nil)
        } catch {
            print("Failed to save user info: \(error)")
        }
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
    }
    
    private func validateInput() {
        guard let text = ageInputField.text, text.count == 4, let year = Int(text) else {
            disableContinueButton()
            hideError()
            return
        }
        
        if year < 1900 || year > 2025 {
            showError(message: "1900 ~ 2025 사이의 값을 입력해주세요.")
            disableContinueButton()
        } else {
            hideError()
            enableContinueButton()
        }
    }
    
    private func showError(message: String) {
        errorLabel.isHidden = false
        errorLabel.text = message
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = ""
    }
    
    private func disableContinueButton() {
        continueButton.isEnabled = false
        continueButton.backgroundColor = .buttonBackground
        ageInputField.textColor = .label
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
    }
    
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        ageInputField.textColor = .accent
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    }

    private func fetchAndDisplayUserInfo() {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            if let first = results.first {
                self.userInfo = first
                if first.age != 0 {
                    ageInputField.text = String(first.age)
                    validateInput()
                }
            } else {
                let newUser = UserInfoEntity(context: context)
                newUser.id = UUID()
                newUser.createdAt = Date()
                self.userInfo = newUser
                try context.save()
            }
        } catch {
            print("Failed to fetch or create user info: \(error)")
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
