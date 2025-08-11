//
//  DiseaseViewController.swift
//  Health
//
//  Created by 권도현 on 8/8/25.
//


import UIKit
import CoreData

class DiseaseViewController: CoreGradientViewController {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var diseaseCollectionView: UICollectionView!
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다음", for: .normal)
        button.setTitleColor(.white, for: .normal)
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
        let backBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButton
        
        fetchUserInfo()
        diseaseCollectionView.reloadData()
        selectUserDiseases()
        updateContinueButtonState()
        view.bringSubviewToFront(continueButton)
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
            if userDiseases.contains(where: { $0 == disease }) {
                let indexPath = IndexPath(item: index, section: 0)
                diseaseCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        }
    }
    
    override func setupHierarchy() {
        [continueButton, progressIndicatorStackView, diseaseCollectionView, descriptionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    override func setupAttribute() {
        progressIndicatorStackView.updateProgress(to: 0.75)
        descriptionLabel.text = "평소 겪는 지병을 골라주세요."
        descriptionLabel.textColor = .label
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
    
    private func setupCollectionView() {
        diseaseCollectionView.delegate = self
        diseaseCollectionView.dataSource = self
        diseaseCollectionView.allowsMultipleSelection = true
        
        if let layout = diseaseCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 10
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets.zero
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
        
        performSegue(withIdentifier: "goToHealthLink", sender: self)
    }
    
    private func updateContinueButtonState() {
        let selectedCount = diseaseCollectionView.indexPathsForSelectedItems?.count ?? 0
        let enabled = selectedCount > 0
        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled ? UIColor.accent : UIColor.buttonBackground
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
        cell.isSelected = false
        return cell
    }
}

extension DiseaseViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return.init() }
        
        let width = (collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right - flowLayout.minimumInteritemSpacing) / 2
        
        return CGSize(width: width, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateContinueButtonState()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateContinueButtonState()
    }
}
