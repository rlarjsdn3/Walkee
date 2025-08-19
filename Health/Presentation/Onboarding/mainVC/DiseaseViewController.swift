//
//  DiseaseViewController.swift
//  Health
//
//  Created by 권도현 on 8/8/25.
//

import UIKit
import HealthKit
import CoreData

class DiseaseViewController: CoreGradientViewController {
    
    @Injected private var stepSyncService: StepSyncService

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var diseaseCollectionView: UICollectionView!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
    private let progressIndicatorStackView = ProgressIndicatorStackView(totalPages: 4)
    private let defaultDiseases: [Disease] = Disease.allCases
    private var userDiseases: [Disease] = []
    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext

    override func initVM() {}

    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient(.midnightBlack)
        setupCollectionView()
        
        continueButton.setTitle("다음", for: .normal)
        continueButton.applyCornerStyle(.medium)
        continueButton.isEnabled = false
        continueButton.titleLabel?.numberOfLines = 1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfo()
        selectUserDiseases()
        updateContinueButtonState()
        updateNavigationBarVisibility()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        diseaseCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateNavigationBarVisibility()
    }
 
    private func updateNavigationBarVisibility() {
        if traitCollection.userInterfaceIdiom == .pad {
            navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }

    private func fetchUserInfo() {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            userInfo = results.first
            userDiseases = userInfo?.diseases ?? []
        } catch {
            print("Failed to fetch UserInfoEntity: \(error)")
            userDiseases = []
        }
    }
    
    private func selectUserDiseases() {
        diseaseCollectionView.reloadData()
        guard !userDiseases.isEmpty else { return }
        
        for (index, disease) in defaultDiseases.enumerated() {
            if userDiseases.contains(disease) {
                let indexPath = IndexPath(item: index, section: 0)
                diseaseCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        }
    }

    override func setupHierarchy() {}
    override func setupAttribute() {
        descriptionLabel.text = "평소 겪는 지병을 골라주세요."
        descriptionLabel.textColor = .label
    }
    override func setupConstraints() {}

    private func setupCollectionView() {
        diseaseCollectionView.delegate = self
        diseaseCollectionView.dataSource = self
        diseaseCollectionView.allowsMultipleSelection = true
        
        if let layout = diseaseCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 10
            layout.minimumLineSpacing = 8
            layout.sectionInset = .zero
        }
        diseaseCollectionView.backgroundColor = .clear
    }

    @IBAction func continueButtonTapped(_ sender: Any) {
        let selectedIndexPaths = diseaseCollectionView.indexPathsForSelectedItems ?? []
        let selectedDiseases = selectedIndexPaths.map { defaultDiseases[$0.item] }

        let context = CoreDataStack.shared.viewContext
        let today = Date().startOfDay()

        userInfo?.diseases = selectedDiseases
        let goal = GoalStepCountEntity(context: context)
        goal.id = UUID()
        goal.effectiveDate = today
        goal.goalStepCount = 10000

        do {
            try context.save()
            print("질병 정보와 임시 목표 걸음 수 저장 완료")
        } catch {
            print("CoreData 저장 실패: \(error.localizedDescription)")
        }

        UserDefaultsWrapper.shared.hasSeenOnboarding = true

        Task {
            do {
                try await stepSyncService.syncSteps()
                print("온보딩 직후 동기화 완료")
            } catch {
                print("온보딩 직후 동기화 실패: \(error.localizedDescription)")
            }
        }

        if let window = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .flatMap({ $0.windows })
                            .first(where: { $0.isKeyWindow }) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let tabBarController = storyboard.instantiateInitialViewController() as? UITabBarController else {
                print("Main.storyboard의 초기 뷰컨트롤러가 UITabBarController가 아닙니다.")
                return
            }

            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
            UIView.transition(with: window,
                              duration: 0.5,
                              options: [.transitionCrossDissolve],
                              animations: nil)
        }
    }
    
    private func updateContinueButtonState() {
        let selectedCount = diseaseCollectionView.indexPathsForSelectedItems?.count ?? 0
        let enabled = selectedCount > 0
        
        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled ? UIColor.accent : UIColor.buttonBackground
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: enabled ? .bold : .regular)
    }
}

extension DiseaseViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return defaultDiseases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "disease", for: indexPath) as? DiseaseCollectionViewCell else {
            return UICollectionViewCell()
        }
        let disease = defaultDiseases[indexPath.item]
        cell.diseaseLabel?.text = disease.localizedName
        return cell
    }
}

extension DiseaseViewController: UICollectionViewDelegateFlowLayout {
    private var noneDiseaseIndex: Int {
        return defaultDiseases.firstIndex(where: { $0 == .none }) ?? defaultDiseases.count - 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }

        let isIpad = traitCollection.userInterfaceIdiom == .pad
        let itemsPerRow: CGFloat = 2
        let spacing = flowLayout.minimumInteritemSpacing
        let totalSpacing = spacing * (itemsPerRow - 1)

        let availableWidth = collectionView.bounds.width - totalSpacing
        var width = floor(availableWidth / itemsPerRow)
   
        if isIpad {
            width *= 0.7
        }
        
        let height: CGFloat = isIpad ? width * 0.5 : 80
 
        let sideInset = (collectionView.bounds.width - (width * itemsPerRow + totalSpacing)) / 2
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == noneDiseaseIndex {
            for i in 0..<defaultDiseases.count where i != noneDiseaseIndex {
                collectionView.deselectItem(at: IndexPath(item: i, section: 0), animated: false)
            }
        } else {
            let noneIndexPath = IndexPath(item: noneDiseaseIndex, section: 0)
            if collectionView.indexPathsForSelectedItems?.contains(noneIndexPath) == true {
                collectionView.deselectItem(at: noneIndexPath, animated: false)
            }
        }
        userDiseases = (collectionView.indexPathsForSelectedItems ?? []).map { defaultDiseases[$0.item] }
        updateContinueButtonState()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        userDiseases = (collectionView.indexPathsForSelectedItems ?? []).map { defaultDiseases[$0.item] }
        updateContinueButtonState()
    }
}
