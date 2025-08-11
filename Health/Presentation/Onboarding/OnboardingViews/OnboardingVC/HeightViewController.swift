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
    
    private let cmLabel: UILabel = {
        let label = UILabel()
        label.text = "cm"
        label.textColor = .accent
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.buttonBackground
        button.setTitleColor(.white, for: .normal)
        button.applyCornerStyle(.medium)
        button.isEnabled = false
        return button
    }()
    
    private let progressIndicatorStackView = ProgressIndicatorStackView(totalPages: 4)
    
    private var continueButtonBottomConstraint: NSLayoutConstraint?
    
    // Core Data
    private let context = CoreDataStack.shared.persistentContainer.viewContext
    private var userInfo: UserInfoEntity?
    
    override func initVM() {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        
        heightInputField.delegate = self
        heightInputField.keyboardType = .numberPad
        heightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        
        let backBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButton
        
        errorLabel.isHidden = true
        errorLabel.textColor = .red
        
        fetchUserInfo()
        
        if let height = userInfo?.height, height > 0 {
            heightInputField.text = String(Int(height))
            validateInput()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressIndicatorStackView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressIndicatorStackView.isHidden = true
    }
    
    override func setupHierarchy() {
        [continueButton, progressIndicatorStackView, cmLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    override func setupAttribute() {
        progressIndicatorStackView.updateProgress(to: 0.625)
    }
    
    override func setupConstraints() {
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            continueButtonBottomConstraint!,
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48),
            
            progressIndicatorStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -24),
            progressIndicatorStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressIndicatorStackView.heightAnchor.constraint(equalToConstant: 4),
            progressIndicatorStackView.widthAnchor.constraint(equalToConstant: 320),
            
            cmLabel.leadingAnchor.constraint(equalTo: heightInputField.trailingAnchor, constant: 8),
            cmLabel.centerYAnchor.constraint(equalTo: heightInputField.centerYAnchor)
        ])
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }
        
        if text.isEmpty {
            hideError()
            disableContinueButton()
        } else if text.count <= 3 {
            validateInput()
        } else {
            textField.text = String(text.prefix(3))
            validateInput()
        }
    }
    
    private func validateInput() {
        guard let text = heightInputField.text, let height = Int(text) else {
            disableContinueButton()
            hideError()
            return
        }
        
        if height > 210 {
            showError()
            disableContinueButton()
            heightInputField.resignFirstResponder()
        } else if height >= 130 {
            hideError()
            enableContinueButton()
            heightInputField.resignFirstResponder()
        } else {
            hideError()
            disableContinueButton()
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
    }
    
    private func enableContinueButton() {
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        heightInputField.textColor = .accent
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        continueButtonBottomConstraint?.constant = -keyboardFrame.height - 10
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
    
    @objc private func continueButtonTapped() {
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
