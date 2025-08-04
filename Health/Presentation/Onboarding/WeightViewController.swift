//
//  WeightViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit

class WeightViewController: CoreViewController {
    
    @IBOutlet weak var weightInputField: UITextField!
    
    private let kgLabel: UILabel = {
        let label = UILabel()
        label.text = "kg"
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
        
        weightInputField.delegate = self
        weightInputField.keyboardType = .numberPad
        weightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // 버튼에 액션 연결
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        let backBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButton
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pageIndicatorStack.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pageIndicatorStack.isHidden = false
    }

    override func setupHierarchy() {
        [continueButton, pageIndicatorStack, kgLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        setupPageIndicators(currentPage: 3)
    }

    override func setupConstraints() {
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            continueButtonBottomConstraint!,
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48),
            
            pageIndicatorStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -24),
            pageIndicatorStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicatorStack.heightAnchor.constraint(equalToConstant: 4),
            pageIndicatorStack.widthAnchor.constraint(equalToConstant: 320),
            
            kgLabel.leadingAnchor.constraint(equalTo: weightInputField.trailingAnchor, constant: 8),
            kgLabel.centerYAnchor.constraint(equalTo: weightInputField.centerYAnchor)
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
        guard let text = weightInputField.text, let weight = Int(text), (40...200).contains(weight) else {
            continueButton.isEnabled = false
            continueButton.backgroundColor = .buttonBackground
            weightInputField.textColor = .label
            return
        }
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        weightInputField.textColor = .accent
    }

    @objc private func didTapContinue() {
        guard continueButton.isEnabled else { return }
        performSegue(withIdentifier: "goToHeightInfo", sender: nil)
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
