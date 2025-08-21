//
//  HealthInfoViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit
import CoreData

class GenderSelectViewController: CoreGradientViewController {

    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleGender: UILabel!
    @IBOutlet weak var maleGender: UILabel!
    
    @IBOutlet weak var femaleWidth: NSLayoutConstraint!
    @IBOutlet weak var femaleHeight: NSLayoutConstraint!
    
    @IBOutlet weak var maleWidth: NSLayoutConstraint!
    @IBOutlet weak var maleHeight: NSLayoutConstraint!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!

    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
    private var originalFemaleWidth: CGFloat = 0
    private var originalFemaleHeight: CGFloat = 0
    private var originalMaleWidth: CGFloat = 0
    private var originalMaleHeight: CGFloat = 0

    private enum Gender: String, CaseIterable {
        case male = "남성"
        case female = "여성"
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

        originalFemaleWidth = femaleWidth.constant
        originalFemaleHeight = femaleHeight.constant
        originalMaleWidth = maleWidth.constant
        originalMaleHeight = maleHeight.constant
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

            let multiplier: CGFloat = 2
            femaleWidth.constant = originalFemaleWidth * multiplier
            femaleHeight.constant = originalFemaleHeight * multiplier
            maleWidth.constant = originalMaleWidth * multiplier
            maleHeight.constant = originalMaleHeight * multiplier

        } else {
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false

            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
            
            femaleWidth.constant = originalFemaleWidth
            femaleHeight.constant = originalFemaleHeight
            maleWidth.constant = originalMaleWidth
            maleHeight.constant = originalMaleHeight
        }
    }
    
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
           
            userInfo.gender = (selectedGender == .male) ? "남성" : "여성"
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
                case "남성": selectedGender = .male
                case "여성": selectedGender = .female
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
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        
        let fontMultiplier: CGFloat = isIpad ? 2.0 : 1.0
        
        let defaultFont = UIFont.systemFont(ofSize: 18 * fontMultiplier, weight: .regular)
        let selectedFont = UIFont.systemFont(ofSize: 18 * fontMultiplier, weight: .bold)
        
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
