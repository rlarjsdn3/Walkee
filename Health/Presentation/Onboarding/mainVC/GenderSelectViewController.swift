//
//  HealthInfoViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

//TODO: 성별 불러오는 명칭 영어 한글 통일 시키기

import UIKit
import CoreData

class GenderSelectViewController: CoreGradientViewController {

    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleGender: UILabel!
    @IBOutlet weak var maleGender: UILabel!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!

    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?

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

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
    
        continueButton.applyCornerStyle(.medium)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        updateGenderSelectionUI()
        updateContinueButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedGender()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
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

    override func initVM() {}
    
    override func setupHierarchy() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)
    }
    
    override func setupAttribute() {
        femaleGender.text = "여성"
        maleGender.text = "남성"
    }

    @IBAction func selectedFM(_ sender: Any) {
        selectedGender = .female
    }
    
    @IBAction func selectedM(_ sender: Any) {
        selectedGender = .male
    }

    @IBAction private func continueButtonTapped(_ sender: Any) {
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
                case "male": selectedGender = .male
                case "female": selectedGender = .female
                default: selectedGender = nil
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
        continueButton.titleLabel?.font = isSelected
            ? UIFont.systemFont(ofSize: 18, weight: .bold)
            : UIFont.systemFont(ofSize: 18, weight: .regular)
    }
}
