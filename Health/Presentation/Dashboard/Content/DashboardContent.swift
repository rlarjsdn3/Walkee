//
//  HomeContent.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

enum DashboardContent {

    enum Section: Hashable {
        ///
        case main
    }

    enum Item: Hashable {
        ///
        case topBar
    }
}

@MainActor
extension DashboardContent.Item {

    func dequeueReusableCollectionViewCell(
        collectionView: UICollectionView,
        topBarCellRegistration: UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void>,
        indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch self {
        case .topBar:
            collectionView.dequeueConfiguredReusableCell(
                using: topBarCellRegistration,
                for: indexPath,
                item: ()
            )
        }
    }
}

@MainActor
extension DashboardContent.Section {

    
}

@MainActor
extension DashboardContent.Section {
    
    func buildLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch self {
        case .main: buildMainLayout(environment)
        }
    }

    private func buildMainLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(50)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(50)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: 8,
            bottom: 0, trailing: 8
        )
        return section
    }
}
