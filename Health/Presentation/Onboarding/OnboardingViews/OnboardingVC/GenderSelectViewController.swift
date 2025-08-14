//
//  HealthInfoViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit
import CoreData

@MainActor
class GenderSelectViewController: CoreGradientViewController, OnboardingStepValidatable {
    
    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleGender: UILabel!
    @IBOutlet weak var maleGender: UILabel!
    
    private enum Gender {
        case male
        case female
    }
    
    private var selectedGender: Gender? {
        didSet {
            updateGenderSelectionUI()
            updateContinueButtonState()
            
            if let parentVC = self.navigationController?.parent as? ProgressContainerViewController {
                parentVC.setBackButtonEnabled(isStepInputValid())
            }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        updateGenderSelectionUI()
        updateContinueButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedGender()
        
        if let parentVC = self.navigationController?.parent as? ProgressContainerViewController {
            parentVC.setBackButtonEnabled(isStepInputValid())
        }
    }
    
    override func initVM() {}
    
    override func setupHierarchy() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)
    }
    
    override func setupAttribute() {
        femaleGender.text = "여성"
        maleGender.text = "남성"
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48)
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
        let selectedBG = UIColor.accent
        
        let defaultTextColor = UIColor.white
        let selectedTextColor = UIColor.black
        
        let defaultFont = UIFont.systemFont(ofSize: 18, weight: .regular)
        let selectedFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        
        femaleButton.tintColor = (selectedGender == .female) ? selectedBG : defaultBG
        maleButton.tintColor = (selectedGender == .male) ? selectedBG : defaultBG
        
        femaleGender.textColor = (selectedGender == .female) ? selectedTextColor : defaultTextColor
        femaleGender.font = (selectedGender == .female) ? selectedFont : defaultFont
        
        maleGender.textColor = (selectedGender == .male) ? selectedTextColor : defaultTextColor
        maleGender.font = (selectedGender == .male) ? selectedFont : defaultFont
    }
    
    private func updateContinueButtonState() {
        let isSelected = (selectedGender != nil)
        continueButton.isEnabled = isSelected
        continueButton.backgroundColor = isSelected ? .accent : .buttonBackground
    }
    
    func isStepInputValid() -> Bool {
        return selectedGender != nil
    }
}
