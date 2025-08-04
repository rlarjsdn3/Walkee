//
//  GenderSelectViewController 2.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit

class SelectAgeViewController: CoreViewController {
    
    @IBOutlet weak var ageInputField: UITextField!
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = UIColor.buttonBackground
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.isEnabled = false
        return button
    }()
    
    private let pageIndicatorStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        return stack
    }()

    private var continueButtonBottomConstraint: NSLayoutConstraint?

    override func initVM() { }

    override func viewDidLoad() {
        super.viewDidLoad()
        ageInputField.delegate = self
        ageInputField.keyboardType = .numberPad
        ageInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        registerForKeyboardNotifications()
    }

    override func setupHierarchy() {
        [continueButton, pageIndicatorStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        setupPageIndicators(currentPage: 2)
    }

    override func setupConstraints() {
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            continueButtonBottomConstraint!,
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 48),
            
            pageIndicatorStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -23),
            pageIndicatorStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicatorStack.heightAnchor.constraint(equalToConstant: 4),
            pageIndicatorStack.widthAnchor.constraint(equalToConstant: 320)
        ])
    }

    private func setupPageIndicators(currentPage: Int) {
        pageIndicatorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for i in 0..<4 {
            let bar = UIView()
            bar.backgroundColor = (i <= currentPage) ? .accent : .buttonBackground
            bar.layer.cornerRadius = 2
            pageIndicatorStack.addArrangedSubview(bar)
        }
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
    }

    private func validateInput() {
        guard let text = ageInputField.text, let year = Int(text), (1900...2025).contains(year) else {
            continueButton.isEnabled = false
            continueButton.backgroundColor = .buttonBackground
            return
        }
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension SelectAgeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let allowedCharacters = CharacterSet.decimalDigits
        if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false
        }

        
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return prospectiveText.count <= 4
    }
}
