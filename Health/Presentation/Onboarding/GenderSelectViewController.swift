//
//  HealthInfoViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit

class GenderSelectViewController: CoreViewController {

    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!

    private enum Gender {
        case male
        case female
    }

    private var selectedGender: Gender? {
        didSet {
            updateGenderSelectionUI()
            updateContinueButtonState()
        }
    }

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

    override func viewDidLoad() {
        super.viewDidLoad()
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        updateGenderSelectionUI()
        updateContinueButtonState()
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

    override func initVM() {}

    override func setupHierarchy() {
        [continueButton, pageIndicatorStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        setupPageIndicators(currentPage: 1)
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48),
            
            pageIndicatorStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -24),
            pageIndicatorStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicatorStack.heightAnchor.constraint(equalToConstant: 4),
            pageIndicatorStack.widthAnchor.constraint(equalToConstant: 320)
        ])
    }

    @IBAction func selectedFM(_ sender: Any) {
        selectedGender = .female
    }

    @IBAction func selectedM(_ sender: Any) {
        selectedGender = .male
    }

    @objc private func continueButtonTapped() {
        guard selectedGender != nil else { return }
        performSegue(withIdentifier: "goToAgeInfo", sender: self)
    }

    private func updateGenderSelectionUI() {
        let defaultBG = UIColor.buttonBackground
        let defaultText = UIColor.white
        let selectedBG = UIColor.accent
        let selectedText = UIColor.label

        if selectedGender == .female {
            femaleButton.tintColor = selectedBG
            femaleButton.setTitleColor(selectedText, for: .normal)
        } else {
            femaleButton.tintColor = defaultBG
            femaleButton.setTitleColor(defaultText, for: .normal)
        }

        if selectedGender == .male {
            maleButton.tintColor = selectedBG
            maleButton.setTitleColor(selectedText, for: .normal)
        } else {
            maleButton.tintColor = defaultBG
            maleButton.setTitleColor(defaultText, for: .normal)
        }
    }

    private func updateContinueButtonState() {
        let isEnabled = (selectedGender != nil)
        continueButton.isEnabled = isEnabled
        continueButton.backgroundColor = isEnabled ? .accent : .buttonBackground
        continueButton.setTitleColor(isEnabled ? .black : .white, for: .normal)
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
}
