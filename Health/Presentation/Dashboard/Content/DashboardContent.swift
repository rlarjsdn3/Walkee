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
        case top
        ///
        case ring
        ///
        case charts
        ///
        case alan
        ///
        case stack

    }

    enum Item: Hashable {
        ///
        case topBar
        ///
        case goalRing(DailyGoalRingCellViewModel)
        ///
        case stackInfo(HealthInfoStackCellViewModel)
        ///
        case barCharts(DashboardBarChartsCellViewModel)
        ///
        case alanSummary(AlanActivitySummaryCellViewModel)
        ///
        case cardInfo(HealthInfoCardCellViewModel)
    }
}

@MainActor
extension DashboardContent.Item {
    
    /// <#Description#>
    /// - Parameters:
    ///   - collectionView: <#collectionView description#>
    ///   - topBarCellRegistration: <#topBarCellRegistration description#>
    ///   - dailyGoalRingCellRegistration: <#dailyGoalRingCellRegistration description#>
    ///   - dailyActivitySummaryCellRegistration: <#dailyActivitySummaryCellRegistration description#>
    ///   - indexPath: <#indexPath description#>
    /// - Returns: <#description#>
    func dequeueReusableCollectionViewCell(
        collectionView: UICollectionView,
        topBarCellRegistration: UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void>,
        dailyGoalRingCellRegistration: UICollectionView.CellRegistration<DailyGoalRingCollectionViewCell, DailyGoalRingCellViewModel>,
        healthInfoStackCellRegistration: UICollectionView.CellRegistration<HealthInfoStackCollectionViewCell, HealthInfoStackCellViewModel>,
        barChartsCellRegistration: UICollectionView.CellRegistration<DashboardBarChartsCollectionViewCell, DashboardBarChartsCellViewModel>,
        alanSummaryCellRegistration: UICollectionView.CellRegistration<AlanActivitySummaryCollectionViewCell, AlanActivitySummaryCellViewModel>,
        healthInfoCardCellRegistration: UICollectionView.CellRegistration<HealthInfoCardCollectionViewCell, HealthInfoCardCellViewModel>,
        indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch self {
        case .topBar:
            return collectionView.dequeueConfiguredReusableCell(
                using: topBarCellRegistration,
                for: indexPath,
                item: ()
            )
        case let .goalRing(viewModel):
            return collectionView.dequeueConfiguredReusableCell(
                using: dailyGoalRingCellRegistration,
                for: indexPath,
                item: viewModel
            )
        case let .stackInfo(viewModel):
            return collectionView.dequeueConfiguredReusableCell(
                using: healthInfoStackCellRegistration,
                for: indexPath,
                item: viewModel
            )
        case let .barCharts(viewModel):
            return collectionView.dequeueConfiguredReusableCell(
                using: barChartsCellRegistration,
                for: indexPath,
                item: viewModel
            )
        case let .alanSummary(viewModel):
            return collectionView.dequeueConfiguredReusableCell(
                using: alanSummaryCellRegistration,
                for: indexPath,
                item: viewModel
            )
        case let .cardInfo(viewModel):
            return collectionView.dequeueConfiguredReusableCell(
                using: healthInfoCardCellRegistration,
                for: indexPath,
                item: viewModel
            )
        }
    }
}

@MainActor
extension DashboardContent.Section {
    
    /// <#Description#>
    /// - Parameters:
    ///   - collectionView: <#collectionView description#>
    ///   - collectionListCellSupplementaryRegistration: <#collectionListCellSupplementaryRegistration description#>
    ///   - indexPath: <#indexPath description#>
    /// - Returns: <#description#>
    func dequeueReusableSupplementaryView(
        collectionView: UICollectionView,
        basicSupplementaryViewRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>,
        indexPath: IndexPath
    ) -> UICollectionReusableView? {
        switch self {
        case .charts, .alan, .stack:
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: basicSupplementaryViewRegistration,
                for: indexPath
            )
        default:
            return nil
        }
    }

}

@MainActor
extension DashboardContent.Section {
    
    /// <#Description#>
    /// - Parameter environment: <#environment description#>
    /// - Returns: <#description#>
    func buildLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch self {
        case .top:      buildTopLayout(environment)
        case .ring:     buildRingLayout(environment)
        case .charts:   buildChartsLayout(environment)
        case .alan:     buildAlanLayout(environment)
        case .stack:    buildStackLayout(environment)
        }
    }

    private func buildTopLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        // TODO: - 레이아웃 재검토 및 수치 조정하기

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
            top: 0, leading: UICollectionViewConstant.defaultInset,
            bottom: 0, trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }

    private func buildRingLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        // TODO: - 레이아웃 재검토 및 수치 조정하기

        let leadingItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.7),
            heightDimension: .fractionalHeight(1.0)
        )
        let leadingItem = NSCollectionLayoutItem(layoutSize: leadingItemSize)

        let trailingItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(0.33)
        )
        let trailingItem = NSCollectionLayoutItem(layoutSize: trailingItemSize)

        let trailingGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.3),
            heightDimension: .fractionalHeight(1.0)
        )
        let trailingGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: trailingGroupSize,
            repeatingSubitem: trailingItem,
            count: 3
        )
        trailingGroup.interItemSpacing = .flexible(8)

        let nestedGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(250)
        )
        let nestedGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: nestedGroupSize,
            subitems: [leadingItem, trailingGroup]
        )
        nestedGroup.interItemSpacing = .flexible(8)

        let section = NSCollectionLayoutSection(group: nestedGroup)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: UICollectionViewConstant.defaultInset,
            bottom: 0, trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }

    private func buildChartsLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        // TODO: - 레이아웃 재검토 및 수치 조정하기

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(300)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(300)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header]

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: UICollectionViewConstant.defaultInset,
            bottom: 0, trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }

    private func buildAlanLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        // TODO: - 레이아웃 코드 작성하기

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(77)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(77)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header]

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: UICollectionViewConstant.defaultInset,
            bottom: 0, trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }

    private func buildStackLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        // TODO: - 레이아웃 코드 작성하기

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(77)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item, item]
        )

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header]

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: UICollectionViewConstant.defaultInset,
            bottom: 0, trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }
}
