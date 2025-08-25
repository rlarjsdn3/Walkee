//
//  WeightViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit
import CoreData

class WeightViewController: CoreGradientViewController {
    
    @IBOutlet weak var weightInputField: DynamicWidthTextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var kgLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabelTopConst: NSLayoutConstraint!
    
    @IBOutlet weak var weightInputFieldCenterY: NSLayoutConstraint!
    private var originalCenterY: CGFloat = 0
    private var originalDescriptionTop: CGFloat = 0
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext
 
    private var shouldPerformSegueAfterKeyboardHide = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient(.midnightBlack)
        
        weightInputField.delegate = self
        weightInputField.keyboardType = .numberPad
        weightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        errorLabel.isHidden = true
        errorLabel.textColor = .red
        
        setupContinueButton()
        
        originalCenterY = weightInputFieldCenterY.constant
        originalDescriptionTop = descriptionLabelTopConst.constant
        
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
        updateDescriptionTopConstraint()
    }
    
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
    
    private func updateDescriptionTopConstraint() {
        let isLandscape = view.bounds.width > view.bounds.height
        descriptionLabelTopConst.constant = originalDescriptionTop * (isLandscape ? 0.3 : 1.2)
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide(_:)),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
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
        
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        weightInputFieldCenterY.constant = originalCenterY
        continueButtonBottomConstraint?.constant = 0
        
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        if shouldPerformSegueAfterKeyboardHide {
            shouldPerformSegueAfterKeyboardHide = false
            performSegue(withIdentifier: "goToHeightInfo", sender: nil)
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
        guard let text = weightInputField.text, let weightValue = Double(text) else { return }
        
        userInfo?.weight = weightValue
        try? context.save()
        
        if weightInputField.isFirstResponder {
            shouldPerformSegueAfterKeyboardHide = true
            view.endEditing(true)
        } else {
            performSegue(withIdentifier: "goToHeightInfo", sender: nil)
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
        textField.invalidateIntrinsicContentSize()
    }
    
    private func validateInput() {
        guard let text = weightInputField.text, !text.isEmpty else {
            disableContinueButton()
            hideError()
            return
        }

        if text.count == 1, text.hasPrefix("0") {
            disableContinueButton()
            weightInputField.text = ""
            return
        }
        
        if let weight = Int(text) {
            switch text.count {
            case 1: disableContinueButton(); hideError()
            case 2,3:
                if (35...200).contains(weight) { enableContinueButton(); hideError() }
                else { disableContinueButton(); showError() }
            default: disableContinueButton(); showError()
            }
        } else { disableContinueButton(); showError() }
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

extension WeightViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: continueButton) == true { return false }
        return true
    }
}
