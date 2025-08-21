//
//  WeightViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

class WeightViewController: CoreGradientViewController {
    
    @IBOutlet weak var weightInputField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var kgLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabelConst: NSLayoutConstraint!
    
    @IBOutlet weak var weightInputFieldCenterY: NSLayoutConstraint!
    private var originalCenterY: CGFloat = 0
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        
        weightInputField.delegate = self
        weightInputField.keyboardType = .numberPad
        weightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        errorLabel.isHidden = true
        errorLabel.textColor = .red
        
        continueButton.applyCornerStyle(.medium)
        originalCenterY = weightInputFieldCenterY.constant
        
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
        updateContinueButtonConstraints()
        updateDescriptionLabelConstraint()
    }
    
    private func updateDescriptionLabelConstraint() {
        let isLandscape = view.bounds.width > view.bounds.height
        descriptionLabelConst.constant = isLandscape
            ? descriptionLabelConst.constant * 0.5
            : descriptionLabelConst.constant * 1.2
    }
    
    private func updateContinueButtonConstraints() {
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
            weightInputFieldCenterY.constant = originalCenterY - keyboardFrame.height * 0.5
        }
        
        continueButtonBottomConstraint?.constant = -(keyboardFrame.height + 20)
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        weightInputFieldCenterY.constant = originalCenterY
        continueButtonBottomConstraint?.constant = -20
        
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
        guard let text = weightInputField.text, let weightValue = Double(text) else { return }
        
        userInfo?.weight = weightValue
        do {
            try context.save()
            performSegue(withIdentifier: "goToHeightInfo", sender: nil)
        } catch {
            print("Failed to save weight: \(error)")
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
    }
    
    private func validateInput() {
        guard let text = weightInputField.text, let weight = Int(text) else {
            disableContinueButton()
            hideError()
            return
        }
        
        switch text.count {
        case 1:
            hideError()
            disableContinueButton()
        case 2:
            if weight >= 35 {
                hideError()
                enableContinueButton()
            } else {
                showError()
                disableContinueButton()
            }
        case 3:
            if weight <= 200 {
                hideError()
                enableContinueButton()
            } else {
                showError()
                disableContinueButton()
            }
        default:
            showError()
            disableContinueButton()
            weightInputField.text = ""
            weightInputField.resignFirstResponder()
        }
    }
    
    private func showError(text: String = "35 ~ 200 사이의 값을 입력해주세요.") {
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
        weightInputField.textColor = .label
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
    }
    
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        weightInputField.textColor = .accent
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    }
    
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
