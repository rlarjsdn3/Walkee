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

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var diseaseCollectionView: UICollectionView!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!

    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewTrailingConstraint: NSLayoutConstraint!
    
    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    
    private var iPadCollectionViewCenterX: NSLayoutConstraint?
    private var iPadCollectionViewCenterY: NSLayoutConstraint?
    private var iPadCollectionViewWidth: NSLayoutConstraint?
    private var iPadCollectionViewHeight: NSLayoutConstraint?
    
    private let progressIndicatorStackView = ProgressIndicatorStackView(totalPages: 4)
    private let defaultDiseases: [Disease] = Disease.allCases
    private var userDiseases: [Disease] = []
    private var userInfo: UserInfoEntity?
    private let context = CoreDataStack.shared.persistentContainer.viewContext

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
        
        let isIpad = traitCollection.userInterfaceIdiom == .pad
        
        if isIpad {
            continueButtonLeading?.isActive = false
            continueButtonTrailing?.isActive = false
            if iPadWidthConstraint == nil {
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
                iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                iPadWidthConstraint?.isActive = true
                iPadCenterXConstraint?.isActive = true
            }

            collectionViewTopConstraint?.isActive = false
            collectionViewBottomConstraint?.isActive = false
            collectionViewLeadingConstraint?.isActive = false
            collectionViewTrailingConstraint?.isActive = false

            if iPadCollectionViewCenterX == nil {
                iPadCollectionViewCenterX = diseaseCollectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                iPadCollectionViewCenterY = diseaseCollectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                iPadCollectionViewWidth = diseaseCollectionView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
                iPadCollectionViewHeight = diseaseCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.475)
                
                iPadCollectionViewCenterX?.isActive = true
                iPadCollectionViewCenterY?.isActive = true
                iPadCollectionViewWidth?.isActive = true
                iPadCollectionViewHeight?.isActive = true
            }
            
        } else {
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false
            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
            
            iPadCollectionViewCenterX?.isActive = false
            iPadCollectionViewCenterY?.isActive = false
            iPadCollectionViewWidth?.isActive = false
            iPadCollectionViewHeight?.isActive = false
            
            collectionViewTopConstraint?.isActive = true
            collectionViewBottomConstraint?.isActive = true
            collectionViewLeadingConstraint?.isActive = true
            collectionViewTrailingConstraint?.isActive = true
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
        navigationController?.setNavigationBarHidden(traitCollection.userInterfaceIdiom == .pad, animated: false)
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
        userInfo?.diseases = selectedDiseases

        do {
            try context.save()
            print("질병 정보 저장 완료")
        } catch {
            print("CoreData 저장 실패: \(error.localizedDescription)")
        }
        performSegue(withIdentifier: "goToStepGoalInfo", sender: self)
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
        cell.diseaseLabel?.text = defaultDiseases[indexPath.item].localizedName
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
        let isLandscape = view.bounds.width > view.bounds.height
        
        var itemsPerRow: CGFloat
        var rows: CGFloat
        
        if isIpad && isLandscape {
            itemsPerRow = 4
            rows = 2
        } else if isIpad {
            itemsPerRow = 2
            rows = 4
        } else {
            itemsPerRow = 2
            rows = 1
        }
        
        let spacing = flowLayout.minimumInteritemSpacing
        let lineSpacing = flowLayout.minimumLineSpacing
        let totalSpacing = spacing * (itemsPerRow - 1)
        let totalLineSpacing = lineSpacing * (rows - 1)
        
        let availableWidth = collectionView.bounds.width - totalSpacing
        let availableHeight = collectionView.bounds.height - totalLineSpacing
        
        let width = floor(availableWidth / itemsPerRow)
        let height: CGFloat
        
        if isIpad {
            height = floor(availableHeight / rows)
            
            let sideInset = max((collectionView.bounds.width - (width * itemsPerRow + totalSpacing)) / 2, 0)
            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
        } else {
            height = 80
            flowLayout.sectionInset = .zero
        }
        
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

