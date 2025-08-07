//
//  SelectAgeViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

class InputAgeViewController: CoreViewController {
    
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

    private var continueButtonBottomConstraint: NSLayoutConstraint?

    private let progressIndicatorStackView = ProgressIndicatorStackView(totalPages: 4)
    
    override func initVM() { }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ageInputField.delegate = self
        ageInputField.keyboardType = .numberPad
        ageInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        
        let backBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButton
        
        errorLabel.isHidden = true
        errorLabel.textColor = .red
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressIndicatorStackView.isHidden = false
        
        // CoreData에 저장된 age 값을 불러와서 텍스트필드에 반영
        fetchAndDisplaySavedAge()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressIndicatorStackView.isHidden = true
    }

    override func setupHierarchy() {
        [continueButton, progressIndicatorStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        progressIndicatorStackView.updateProgress(to: 0.375)
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
            progressIndicatorStackView.widthAnchor.constraint(equalToConstant: 320)
        ])
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, text.count == 4 {
            validateInput()
            textField.resignFirstResponder()
        } else {
            hideError()
            disableContinueButton()
        }
    }

    private func validateInput() {
        guard let text = ageInputField.text, let year = Int(text) else {
            disableContinueButton()
            hideError()
            return
        }
        
        if year < 1900 || year > 2025 {
            ageInputField.text = ""
            showError()
            disableContinueButton()
        } else {
            hideError()
            enableContinueButton()
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

        let context = CoreDataStack.shared.viewContext
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            let userInfo: UserInfoEntity
            
            if let existing = results.first {
                userInfo = existing
            } else {
                userInfo = UserInfoEntity(context: context)
                userInfo.id = UUID()
                userInfo.createdAt = Date()
            }
            
            userInfo.age = year
            
            CoreDataStack.shared.saveContext()
            performSegue(withIdentifier: "goToWeightInfo", sender: nil)
            
        } catch {
            print("CoreData 저장 중 오류 발생: \(error)")
        }
    }
    
    private func fetchAndDisplaySavedAge() {
        let context = CoreDataStack.shared.viewContext
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            if let userInfo = results.first {
                let age = userInfo.age
                if age != 0 {
                    ageInputField.text = String(age)
                    enableContinueButton()
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

    deinit {
        NotificationCenter.default.removeObserver(self)
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
