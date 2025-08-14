//
//  SelectAgeViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

@MainActor
class InputAgeViewController: CoreGradientViewController, OnboardingStepValidatable {
    
    @IBOutlet weak var ageInputField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.buttonBackground
        button.setTitleColor(.white, for: .normal)
        button.applyCornerStyle(.medium)
        button.isEnabled = false
        return button
    }()
    
    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext
    private var continueButtonBottomConstraint: NSLayoutConstraint?
    
    override func initVM() { }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        
        ageInputField.delegate = self
        ageInputField.keyboardType = .numberPad
        ageInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        
        errorLabel.isHidden = true
        errorLabel.textColor = .red
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if ageInputField.text?.isEmpty ?? true {
            ageInputField.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfo()
        fetchAndDisplaySavedAge()
        
        if let parentVC = self.navigationController?.parent as? ProgressContainerViewController {
            parentVC.setBackButtonEnabled(isStepInputValid())
        }
    }
    
    override func setupHierarchy() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)
    }
    
    override func setupConstraints() {
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            continueButtonBottomConstraint!,
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48)
        ])
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
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
        if let parentVC = self.navigationController?.parent as? ProgressContainerViewController {
            parentVC.setBackButtonEnabled(isStepInputValid())
        }
    }
    
    private func validateInput() {
        guard let text = ageInputField.text, let year = Int(text) else {
            disableContinueButton()
            hideError()
            return
        }
        
        if year < 1900 || year > 2025 {
            showError()
            disableContinueButton()
        } else {
            hideError()
            enableContinueButton()
            ageInputField.resignFirstResponder()
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
    }
    
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        ageInputField.textColor = .accent
    }
    
    @objc private func didTapContinue() {
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
    
    func isStepInputValid() -> Bool {
        guard let text = ageInputField.text, let year = Int(text) else {
            return false
        }
        return year >= 1900 && year <= 2025
    }
}

extension InputAgeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false
        }
        
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return prospectiveText.count <= 4
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
