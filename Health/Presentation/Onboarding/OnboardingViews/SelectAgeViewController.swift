import UIKit

class SelectAgeViewController: CoreViewController {
    
    @IBOutlet weak var ageInputField: UITextField!
    
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
        [continueButton, pageIndicatorStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        setupPageIndicators(progress: 0.375)
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
            pageIndicatorStack.widthAnchor.constraint(equalToConstant: 320)
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
        guard let text = ageInputField.text, let year = Int(text), (1900...2025).contains(year) else {
            continueButton.isEnabled = false
            continueButton.backgroundColor = .buttonBackground
            ageInputField.textColor = .label // 기본색
            return
        }
        continueButton.isEnabled = true
        continueButton.backgroundColor = .accent
        ageInputField.textColor = .accent
    }
    
    @objc private func didTapContinue() {
        guard continueButton.isEnabled else { return }
        performSegue(withIdentifier: "goToWeightInfo", sender: nil)
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
