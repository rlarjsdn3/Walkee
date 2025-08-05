//
//  HeightViewController.swift
//  Health
//
//  Created by 권도현 on 8/4/25.
//

import UIKit

class HeightViewController: CoreViewController {

    @IBOutlet weak var heightInputField: UITextField!
    
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
        button.layer.cornerRadius = 12
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

    override func initVM() {}

    override func viewDidLoad() {
        super.viewDidLoad()
        
        heightInputField.delegate = self
        heightInputField.keyboardType = .numberPad
        heightInputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        registerForKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        let backBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pageIndicatorStack.isHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pageIndicatorStack.isHidden = true
    }
    
    override func setupHierarchy() {
        [continueButton, pageIndicatorStack, cmLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        setupPageIndicators(progress: 0.625)
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
            
            cmLabel.leadingAnchor.constraint(equalTo: heightInputField.trailingAnchor, constant: 8),
            cmLabel.centerYAnchor.constraint(equalTo: heightInputField.centerYAnchor)
        ])
    }

    private func setupPageIndicators(progress: CGFloat) {
        pageIndicatorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let totalPages = 4
        let clampedProgress = max(0, min(progress, 1))
        let totalProgress = CGFloat(totalPages) * clampedProgress

        for i in 0..<totalPages {
            let containerView = UIView()
            containerView.backgroundColor = .buttonBackground
            containerView.layer.cornerRadius = 2
            containerView.clipsToBounds = true

            let progressBar = UIView()
            progressBar.backgroundColor = .accent
            progressBar.translatesAutoresizingMaskIntoConstraints = false

            containerView.addSubview(progressBar)

            let fillRatio: CGFloat
            if totalProgress > CGFloat(i + 1) {
                fillRatio = 1.0
            } else if totalProgress > CGFloat(i) {
                fillRatio = totalProgress - CGFloat(i)
            } else {
                fillRatio = 0.0
            }

            NSLayoutConstraint.activate([
                progressBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                progressBar.topAnchor.constraint(equalTo: containerView.topAnchor),
                progressBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                progressBar.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: fillRatio)
            ])

            pageIndicatorStack.addArrangedSubview(containerView)

            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.heightAnchor.constraint(equalToConstant: 4).isActive = true
        }
    }
    @objc private func textFieldDidChange(_ textField: UITextField) {
        validateInput()
    }

    private func validateInput() {
        guard let text = heightInputField.text, let weight = Int(text), (100...250).contains(weight) else {
            continueButton.isEnabled = false
            continueButton.backgroundColor = .buttonBackground
            heightInputField.textColor = .label
            return
        }
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
