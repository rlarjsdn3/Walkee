//
//  PersonalContent.swift
//  Health
//
//  Created by juks86 on 8/5/25.
//

import UIKit

enum PersonalContent {

    // 섹션 정의
    enum Section: Hashable {
        case segment
        case chart
    }

    // 아이템 정의
    enum Item: Hashable {
        case segmentControl
        case chartData
    }
}

@MainActor
extension PersonalContent.Item {

    /// 컬렉션 뷰 셀 dequeue
    func dequeueReusableCollectionViewCell(
        collectionView: UICollectionView,
        segmentCellRegistration: UICollectionView.CellRegistration<SegmentControlCell, Void>,
        chartCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch self {
        case .segmentControl:
            return collectionView.dequeueConfiguredReusableCell(
                using: segmentCellRegistration,
                for: indexPath,
                item: ()
            )
        case.chartData:
            return collectionView.dequeueConfiguredReusableCell(
                using: chartCellRegistration,
                for: indexPath,
                item: ()
            )
        }
    }
}

@MainActor
extension PersonalContent.Section {

    /// 섹션에 맞는 레이아웃 빌드
    func buildLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch self {
        case .segment:
            return buildMainLayout(environment)
        case .chart:
            return buildChartLayout(environment)
        }
    }
    /// 섹션 레이아웃 정의
    private func buildMainLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: UICollectionViewConstant.defaultInset,
            bottom: 0,
            trailing: UICollectionViewConstant.defaultInset
        )

        return section
    }

    private func buildChartLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: UICollectionViewConstant.defaultInset,
            bottom: 0,
            trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }
}
