//
//  HeightViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

class HeightViewController: CoreGradientViewController {
    
    @IBOutlet weak var heightInputField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var cmLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
    private let context = CoreDataStack.shared.persistentContainer.viewContext
    private var userInfo: UserInfoEntity?
    
    override func initVM() {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        
        heightInputField.delegate = self
        heightInputField.keyboardType = .numberPad
        heightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        continueButton.applyCornerStyle(.medium)
        continueButton.isEnabled = false
        continueButton.backgroundColor = .buttonBackground
        continueButton.setTitleColor(.label, for: .normal)
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        errorLabel.isHidden = true
        errorLabel.textColor = .red
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfo()
        fetchAndDisplaySavedHeight()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if heightInputField.text?.isEmpty ?? true {
            heightInputField.becomeFirstResponder()
        }
    }
    
    private func fetchUserInfo() {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            if let first = results.first {
                self.userInfo = first
            } else {
                let newUser = UserInfoEntity(context: context)
                newUser.id = UUID()
                newUser.createdAt = Date()
                self.userInfo = newUser
                try context.save()
            }
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    private func fetchAndDisplaySavedHeight() {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            if let userInfo = results.first, userInfo.height > 0 {
                self.userInfo = userInfo
                heightInputField.text = String(Int(userInfo.height))
                validateInput()
            }
        } catch {
            print("CoreData에서 height 불러오기 실패: \(error)")
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }
        
        if let height = Double(text) {
            userInfo?.height = height
            validateInput()
        } else {
            disableContinueButton()
        }
    }
    
    private func validateInput() {
        guard let text = heightInputField.text, let height = Int(text) else {
            disableContinueButton()
            hideError()
            return
        }
        
        switch text.count {
        case 1, 2:
            hideError()
            disableContinueButton()
            
        case 3:
            if height < 130 {
                showError()
                disableContinueButton()
                heightInputField.text = ""
                
            } else if height <= 210 {
                hideError()
                enableContinueButton()
                
            } else {
                showError()
                disableContinueButton()
                heightInputField.text = ""
            }
        default:
            showError()
            disableContinueButton()
            heightInputField.text = ""
        }
    }
    
    private func showError(text: String = "130 ~ 210 사이의 값을 입력해주세요.") {
        errorLabel.isHidden = false
        errorLabel.text = text
        errorLabel.textColor = .red
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = ""
    }
    
    private func disableContinueButton() {
        continueButton.isEnabled = false
        continueButton.backgroundColor = .buttonBackground
        heightInputField.textColor = .label
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    }
    
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        heightInputField.textColor = .accent
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        guard continueButton.isEnabled,
              let text = heightInputField.text,
              let heightValue = Double(text) else { return }
        
        userInfo?.height = heightValue
        do {
            try context.save()
            performSegue(withIdentifier: "goToDiseaseTap", sender: self)
        } catch {
            print("Failed to save height: \(error)")
        }
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        continueButtonBottomConstraint?.constant = -keyboardFrame.height
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        continueButtonBottomConstraint?.constant = -20
        UIView.animate(withDuration: 0.3) {
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
}

extension HeightViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false
        }
        
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return prospectiveText.count <= 3
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
