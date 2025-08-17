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
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.buttonBackground
        button.setTitleColor(.label, for: .normal)
        button.applyCornerStyle(.medium)
        button.isEnabled = false
        return button
    }()
    
    private var continueButtonBottomConstraint: NSLayoutConstraint?
    private let context = CoreDataStack.shared.persistentContainer.viewContext
    private var userInfo: UserInfoEntity?
    
    var onContinue: (() -> Void)?
    
    override func initVM() { }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        weightInputField.delegate = self
        weightInputField.keyboardType = .numberPad
        weightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        
        errorLabel.isHidden = true
        errorLabel.textColor = .red
        fetchUserInfo()
        
        if let weight = userInfo?.weight, weight > 0 {
            weightInputField.text = String(Int(weight))
            validateInput()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if weightInputField.text?.isEmpty ?? true {
            weightInputField.becomeFirstResponder()
        }
    }
    
    override func setupHierarchy() {
        [continueButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    override func setupConstraints() {
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        NSLayoutConstraint.activate([
            continueButtonBottomConstraint!,
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48),
        ])
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
    
    @objc private func didTapContinue() {
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
        guard let text = textField.text else { return }
        
        if text.isEmpty {
            hideError()
            disableContinueButton()
        } else if text.count <= 3 {
            validateInput()
        } else {
            hideError()
            disableContinueButton()
        }
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
                weightInputField.text = ""
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
    }
    
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        weightInputField.textColor = .accent
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
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

extension WeightViewController: UITextFieldDelegate {
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
