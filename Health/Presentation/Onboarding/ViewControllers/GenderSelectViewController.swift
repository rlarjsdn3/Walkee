//
//  HealthInfoViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit
import CoreData

class GenderSelectViewController: CoreGradientViewController {

    //제약
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
    @IBOutlet weak var descriptionTopConst: NSLayoutConstraint!
    
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
    private var originalDescriptionTop: CGFloat = 0
    private var originalFemaleWidth: CGFloat = 0
    private var originalFemaleHeight: CGFloat = 0
    private var originalMaleWidth: CGFloat = 0
    private var originalMaleHeight: CGFloat = 0

    //성별 배열
    private enum Gender: String {
        case male = "남성"
        case female = "여성"
    }
    
    //선택된 성별 선언
    private var selectedGender: Gender? {
        didSet {
            updateGenderSelectionUI()
            updateContinueButtonState()
        }
    }

    //라이프 사이클
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        
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
            switch button.state
            {
            case .highlighted:
                self?.continueButton.alpha = 0.75
            default: self?.continueButton.alpha = 1.0
            }
        }
        continueButton.configuration = config
        continueButton.applyCornerStyle(.medium)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)

        updateGenderSelectionUI()
        updateContinueButtonState()

        originalFemaleWidth = femaleWidth.constant
        originalFemaleHeight = femaleHeight.constant
        originalMaleWidth = maleWidth.constant
        originalMaleHeight = maleHeight.constant
        originalDescriptionTop = descriptionTopConst.constant
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedGender()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateTraitsConstraints()
        updateDescriptionTopConstraint()
    }
    
    //기기의 환경이 변했을때 적용
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateGenderSelectionUI()
        updateContinueButtonState()
    }
    
    // UI 변동사항
    override func setupAttribute() {
        femaleGender.text = "여성"
        maleGender.text = "남성"
    }

    //버튼 액션
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

    //설명 탑 제약 대응 코드
    private func updateDescriptionTopConstraint() {
        // iPad 여부
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
                     traitCollection.verticalSizeClass == .regular
        let isLandscape = view.bounds.width > view.bounds.height

        if isIpad {
            // 아이패드 고정값 지정
            descriptionTopConst.constant = isLandscape ? 28 : 80
        } else {
            // 아이폰은 세로모드만 사용 → 스토리보드 제약 그대로 사용
            descriptionTopConst.constant = originalDescriptionTop
        }
    }
    
    // 화면 요소 아이폰, 아이패드 대응 코드
    private func updateTraitsConstraints() {
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

            let multiplier: CGFloat = 1.8
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
    
    // 코어데이터 저장 코드
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

    //성별버튼 업데이트 코드
    private func updateGenderSelectionUI() {
        let selectedTextColor = UIColor.systemBackground
        let defaultTextColor = UIColor.label
        
        femaleGender.textColor = (selectedGender == .female) ? selectedTextColor : defaultTextColor
        maleGender.textColor = (selectedGender == .male) ? selectedTextColor : defaultTextColor
        
        femaleButton.tintColor = (selectedGender == .female) ? .accent : .systemGray5
        maleButton.tintColor = (selectedGender == .male) ? .accent : .systemGray5
        
        //현재 폰트는 선택/ 미선택 모두 semibold로 통합
//        if let currentFont = femaleGender.font {
//            femaleGender.font = (selectedGender == .female) ? currentFont.withBoldTrait() : currentFont.withNormalTrait()
//        }
//        if let currentFont = maleGender.font {
//            maleGender.font = (selectedGender == .male) ? currentFont.withBoldTrait() : currentFont.withNormalTrait()
//        }
    }
    
    //다음버튼 업데이트 코드
    private func updateContinueButtonState() {
        let isSelected = (selectedGender != nil)
        continueButton.isEnabled = isSelected
        continueButton.backgroundColor = isSelected ? .accent : .buttonBackground
        
        if let currentFont = continueButton.titleLabel?.font {
            continueButton.titleLabel?.font = isSelected ? currentFont.withBoldTrait() : currentFont.withNormalTrait()
        }
    }
}

// 폰트 매서드 확장 코드
extension UIFont {
    func withBoldTrait() -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(self.fontDescriptor.symbolicTraits.union(.traitBold)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }

    func withNormalTrait() -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(self.fontDescriptor.symbolicTraits.subtracting(.traitBold)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
