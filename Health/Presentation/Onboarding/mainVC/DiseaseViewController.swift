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
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.applyCornerStyle(.medium)
        button.isEnabled = false
        button.backgroundColor = UIColor.buttonBackground
        return button
    }()
    
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
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        view.bringSubviewToFront(continueButton)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfo()
        selectUserDiseases()
        updateContinueButtonState()
        updateNavigationBarVisibility()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        diseaseCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    // 회전/trait 변화 시 네비게이션바 처리
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
        guard !userDiseases.isEmpty else { return }
        for (index, disease) in defaultDiseases.enumerated() {
            if userDiseases.contains(disease) {
                let indexPath = IndexPath(item: index, section: 0)
                diseaseCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        }
    }

    override func setupHierarchy() {
        [continueButton, diseaseCollectionView, descriptionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    override func setupAttribute() {
        descriptionLabel.text = "평소 겪는 지병을 골라주세요."
        descriptionLabel.textColor = .label
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 48)
        ])
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

    @objc private func continueButtonTapped() {
        let selectedIndexPaths = diseaseCollectionView.indexPathsForSelectedItems ?? []
        let selectedDiseases = selectedIndexPaths.map { defaultDiseases[$0.item] }
        userInfo?.diseases = selectedDiseases
        do {
            try context.save()
        } catch {
            print("Failed to save diseases to CoreData: \(error)")
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBarController = storyboard.instantiateInitialViewController() as? UITabBarController else {
            print("Main.storyboard의 초기 뷰컨트롤러가 UITabBarController가 아닙니다.")
            return
        }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
            UIView.transition(with: window,
                              duration: 0.5,
                              options: [.transitionCrossDissolve],
                              animations: nil)
        }
        UserDefaultsWrapper.shared.hasSeenOnboarding = true
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

