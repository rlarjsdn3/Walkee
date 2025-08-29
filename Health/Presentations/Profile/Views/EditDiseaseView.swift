//
//  EditDiseaseView.swift
//  Health
//
//  Created by 하재준 on 8/20/25.
//

import UIKit

class EditDiseaseView: CoreView {
    
    private enum Section {
        case main
    }
    
    private var lastIsLandscape: Bool?
    
    private let titleLabel = UILabel()
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeLayout()
        )
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.allowsMultipleSelection = true
        cv.delegate = self
        return cv
    }()
    
    var userDiseases: [Disease] = [] {
        didSet { onSelectionChange?(userDiseases) }
    }
    
    var onSelectionChange: (([Disease]) -> Void)?
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Disease> = makeDataSource()
    private var diseaseItems: [Disease] = Disease.allCases
    
    override func setupHierarchy() {
        addSubviews(titleLabel, collectionView)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        titleLabel.configureAsTitle("지병")
        
        collectionView.register(EditDiseaseCollectionViewCell.self, forCellWithReuseIdentifier: EditDiseaseCollectionViewCell.id)
        collectionView.isScrollEnabled = false
        applySnapshot(animated: false)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateCollectionViewSelectionIfNeeded()
        }
    }
    
    override func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        lastIsLandscape = isLandscapeNow()
        collectionView.setCollectionViewLayout(makeLayout(), animated: false)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            setNeedsLayout()
        }
        let now = isLandscapeNow()
        guard now != lastIsLandscape else { return } // 같은 방향이면 패스
        lastIsLandscape = now
        collectionView.setCollectionViewLayout(makeLayout(), animated: false)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let now = isLandscapeNow()
        if now != lastIsLandscape {
            lastIsLandscape = now
            collectionView.setCollectionViewLayout(makeLayout(), animated: false)
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func getSelectedDiseases() -> [Disease] {
        return userDiseases
    }
    
    // 기존에 저장된 질병들을 설정하고 UI에 선택 상태로 표시하는 메서드
    func setSelectedDiseases(_ diseases: [Disease]) {
        clearAllSelections()
        
        userDiseases = diseases
        
        // UI에 선택 상태 반영 (약간의 지연을 주어 collectionView가 준비된 후 실행)
        DispatchQueue.main.async { [weak self] in
            self?.updateCollectionViewSelection()
        }
    }
    
    private func clearAllSelections() {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else { return }
        for indexPath in selectedIndexPaths {
            collectionView.deselectItem(at: indexPath, animated: false)
        }
    }
    
    private func updateCollectionViewSelection() {
        for disease in userDiseases {
            if let index = diseaseItems.firstIndex(of: disease) {
                let indexPath = IndexPath(item: index, section: 0)
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        }
    }
    
    private func updateCollectionViewSelectionIfNeeded() {
        // userDiseases가 비어있지 않으면 선택 상태 업데이트
        if !userDiseases.isEmpty {
            updateCollectionViewSelection()
        }
    }
    
    private func isLandscapeNow() -> Bool {
        if let scene = window?.windowScene {
            return scene.interfaceOrientation.isLandscape
        }
        return bounds.width > bounds.height
    }
    
    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Disease> {
        UICollectionViewDiffableDataSource<Section, Disease>(
            collectionView: collectionView
        ) { cv, indexPath, disease in
            let cell = cv.dequeueReusableCell(
                withReuseIdentifier: EditDiseaseCollectionViewCell.id,
                for: indexPath
            ) as! EditDiseaseCollectionViewCell
            cell.configure(disease)
            return cell
        }
    }
    
    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Disease>()
        snapshot.appendSections([.main])
        snapshot.appendItems(diseaseItems)
        
        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            DispatchQueue.main.async {
                if self?.userDiseases.isEmpty == false {
                    self?.updateCollectionViewSelection()
                }
            }
        }
    }
    
    private func makeLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, env in
            let tc = env.traitCollection
            let isPad = tc.userInterfaceIdiom == .pad
            let isLandscape: Bool = {
                if let scene = self.window?.windowScene {
                    return scene.interfaceOrientation.isLandscape
                } else {
                    // fallback
                    return UIScreen.main.bounds.width > UIScreen.main.bounds.height
                }
            }()
            print("Device: \(isPad ? "iPad" : "iPhone")")
            print("IsLandScape: \(isLandscape)")
            
            
            let rowSpacing: CGFloat = isPad ? 16 : 12
            let colSpacing: CGFloat = isPad ? 16 : 12
            let cellHeight: CGFloat = isPad
            ? 112
            : self.bounds.height / 6
            
            if isPad {
                // iPad 레이아웃 (항상 2행 4열)
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .fractionalHeight(1.0))
                )
                let rowGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .absolute(cellHeight)),
                    subitem: item,
                    count: 4
                )
                rowGroup.interItemSpacing = .fixed(colSpacing)
                
                let gridGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .absolute(cellHeight * 2 + rowSpacing)),
                    subitem: rowGroup,
                    count: 2
                )
                gridGroup.interItemSpacing = .fixed(rowSpacing)
                
                let section = NSCollectionLayoutSection(group: gridGroup)
                section.interGroupSpacing = rowSpacing
                section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
                return section
            } else {
                // iPhone 레이아웃 (항상 4행 2열)
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .fractionalHeight(1.0))
                )
                let rowGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .absolute(cellHeight)),
                    subitem: item,
                    count: 2
                )
                rowGroup.interItemSpacing = .fixed(colSpacing)
                
                let gridGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .absolute(cellHeight * 4 + rowSpacing * 3)),
                    subitem: rowGroup,
                    count: 4
                )
                gridGroup.interItemSpacing = .fixed(rowSpacing)
                
                let section = NSCollectionLayoutSection(group: gridGroup)
                section.interGroupSpacing = rowSpacing
                section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
                return section
            }
        }
    }
    
    func deselectAll(except keep: IndexPath?, animated: Bool) {
        for ip in collectionView.indexPathsForSelectedItems ?? [] where ip != keep {
            collectionView.deselectItem(at: ip, animated: animated)
        }
    }
    
    func deselectNoneIfSelected(animated: Bool) {
        guard let noneIdx = diseaseItems.firstIndex(of: .none) else { return }
        let noneIP = IndexPath(item: noneIdx, section: 0)
        if (collectionView.indexPathsForSelectedItems ?? []).contains(noneIP) {
            collectionView.deselectItem(at: noneIP, animated: animated)
        }
    }
    
    private func addDisease(_ disease: Disease) {
        if disease == .none {
            userDiseases = [.none]
            return
        }
        if let idx = userDiseases.firstIndex(of: .none) {
            userDiseases.remove(at: idx)
        }
        // 중복 추가 방지
        if !userDiseases.contains(disease) {
            userDiseases.append(disease)
        }
        
    }
    
    private func removeDisease(_ disease: Disease) {
        if let idx = userDiseases.firstIndex(of: disease) {
            userDiseases.remove(at: idx)
        }        
    }
}

extension EditDiseaseView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tapped = diseaseItems[indexPath.item]
        
        if tapped == .none {
            deselectAll(except: indexPath, animated: false)
            userDiseases = [.none]
        } else {
            deselectNoneIfSelected(animated: false)
            addDisease(tapped)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let tapped = diseaseItems[indexPath.item]
        removeDisease(tapped)
    }
}
