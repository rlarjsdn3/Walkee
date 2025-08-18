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
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
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
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        disableContinueButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfo()
        fetchAndDisplaySavedAge()
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

    @IBAction func continueButtonTapped(_ sender: UIButton) {
        guard continueButton.isEnabled else { return }
        guard let text = ageInputField.text, let year = Int16(text) else { return }
        
        userInfo?.age = year
        do {
            try context.save()
            performSegue(withIdentifier: "goToWeightInfo", sender: nil)
        } catch {
            print("CoreData 저장 중 오류 발생: \(error)")
        }
    }
  
    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
    }
    
    private func validateInput() {
        guard let text = ageInputField.text else {
            disableContinueButton()
            hideError()
            return
        }
        
        if text.count == 4, let year = Int(text) {
            if year < 1900 || year > 2025 {
                showError()
                disableContinueButton()
                ageInputField.text = ""
            } else {
                hideError()
                enableContinueButton()
            }
        } else {
            disableContinueButton()
            hideError()
        }
    }
    
    private func showError() {
        errorLabel.isHidden = false
        errorLabel.text = "1900 ~ 2025 사이의 값을 입력해주세요."
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
    
    private func fetchAndDisplaySavedAge() {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            if let userInfo = results.first {
                self.userInfo = userInfo
                let age = userInfo.age
                if age != 0 {
                    ageInputField.text = String(age)
                    validateInput()
                }
            }
        } catch {
            print("CoreData에서 age 불러오기 실패: \(error)")
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
