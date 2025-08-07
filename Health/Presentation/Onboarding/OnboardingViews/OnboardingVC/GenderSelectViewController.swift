//
//  HealthInfoViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit
import CoreData

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
        button.applyCornerStyle(.medium)
        button.isEnabled = false 
        return button
    }()

    private let progressIndicatorStackView = ProgressIndicatorStackView(totalPages: 4)

    override func viewDidLoad() {
        super.viewDidLoad()
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        updateGenderSelectionUI()
        updateContinueButtonState()
        let backBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressIndicatorStackView.isHidden = false
        loadSavedGender()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressIndicatorStackView.isHidden = true
    }

    override func initVM() {}

    override func setupHierarchy() {
        [continueButton, progressIndicatorStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        progressIndicatorStackView.updateProgress(to: 0.25)
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48),

            progressIndicatorStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -24),
            progressIndicatorStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressIndicatorStackView.heightAnchor.constraint(equalToConstant: 4),
            progressIndicatorStackView.widthAnchor.constraint(equalToConstant: 320)
        ])
    }

    @IBAction func selectedFM(_ sender: Any) {
        selectedGender = .female
    }

    @IBAction func selectedM(_ sender: Any) {
        selectedGender = .male
    }

    @objc private func continueButtonTapped() {
        guard let selectedGender = selectedGender else { return }

        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            let userInfo: UserInfoEntity

            if let existing = results.first {
                userInfo = existing
            } else {
                userInfo = UserInfoEntity(context: context)
                userInfo.id = UUID()
                userInfo.createdAt = Date()
            }

            userInfo.gender = (selectedGender == .male) ? "male" : "female"
            CoreDataStack.shared.saveContext()
        } catch {
            print("CoreData 저장 오류: \(error.localizedDescription)")
            return
        }

        performSegue(withIdentifier: "goToAgeInfo", sender: self)
    }

    private func loadSavedGender() {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()

        do {
            if let userInfo = try context.fetch(fetchRequest).first,
               let genderString = userInfo.gender {
                switch genderString {
                case "male":
                    selectedGender = .male
                case "female":
                    selectedGender = .female
                default:
                    selectedGender = nil
                }
            } else {
                selectedGender = nil
            }
        } catch {
            print("Failed to fetch gender from CoreData: \(error.localizedDescription)")
            selectedGender = nil
        }
    }

    private func updateGenderSelectionUI() {
        let defaultBG = UIColor.buttonBackground
        let defaultText = UIColor.white
        let selectedBG = UIColor.accent
        let selectedText = UIColor.label

        femaleButton.tintColor = (selectedGender == .female) ? selectedBG : defaultBG
        femaleButton.setTitleColor((selectedGender == .female) ? selectedText : defaultText, for: .normal)

        maleButton.tintColor = (selectedGender == .male) ? selectedBG : defaultBG
        maleButton.setTitleColor((selectedGender == .male) ? selectedText : defaultText, for: .normal)
    }

    private func updateContinueButtonState() {
        let isSelected = (selectedGender != nil)
        continueButton.isEnabled = isSelected
        continueButton.backgroundColor = isSelected ? .accent : .buttonBackground
        continueButton.setTitleColor(isSelected ? .black : .white, for: .normal)
    }
}
