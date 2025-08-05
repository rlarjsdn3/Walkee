//
//  HomeContent.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

enum DashboardContent {

    enum Section: Hashable {
        /// 대시보드 상단 섹션
        case top
        /// 목표 링 및 건강 정보 스택 섹션
        case ring
        /// 활동 차트 섹션
        case charts
        /// AI 요약 정보 섹션
        case alan
        /// 건강 카드 정보 섹션
        case card
        /// 대시보드 하단 섹션
        case bottom
    }

    enum Item: Hashable {
        /// 상단 바 항목
        case topBar
        /// 목표 링 셀
        case goalRing(DailyGoalRingCellViewModel)
        /// 건강 정보 스택 셀
        case stackInfo(HealthInfoStackCellViewModel)
        /// 막대 차트 셀
        case barCharts(DashboardBarChartsCellViewModel)
        /// AI 요약 셀
        case alanSummary(AlanActivitySummaryCellViewModel)
        /// 건강 카드 셀
        case cardInfo(HealthInfoCardCellViewModel)
        /// 일반 텍스트 셀
        case text(TextCellViewModel)
    }
}

@MainActor
extension DashboardContent.Item {

    func dequeueReusableCollectionViewCell(
        collectionView: UICollectionView,
        topBarCellRegistration: UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void>,
        dailyGoalRingCellRegistration: UICollectionView.CellRegistration<DailyGoalRingCollectionViewCell, DailyGoalRingCellViewModel>,
        healthInfoStackCellRegistration: UICollectionView.CellRegistration<HealthInfoStackCollectionViewCell, HealthInfoStackCellViewModel>,
        barChartsCellRegistration: UICollectionView.CellRegistration<DashboardBarChartsCollectionViewCell, DashboardBarChartsCellViewModel>,
        alanSummaryCellRegistration: UICollectionView.CellRegistration<AlanActivitySummaryCollectionViewCell, AlanActivitySummaryCellViewModel>,
        healthInfoCardCellRegistration: UICollectionView.CellRegistration<HealthInfoCardCollectionViewCell, HealthInfoCardCellViewModel>,
        textCellRegistration: UICollectionView.CellRegistration<TextCollectionViewCell, TextCellViewModel>,
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

        case let .text(viewModel):
            return collectionView.dequeueConfiguredReusableCell(
                using: textCellRegistration,
                for: indexPath,
                item: viewModel
            )
        }
    }
}

@MainActor
extension DashboardContent.Section {

    func dequeueReusableSupplementaryView(
        collectionView: UICollectionView,
        basicSupplementaryViewRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>,
        indexPath: IndexPath
    ) -> UICollectionReusableView? {
        switch self {
        case .charts, .alan, .card:
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
    
    func buildLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch self {
        case .top:      buildTopLayout(environment)
        case .ring:     buildRingLayout(environment)
        case .charts:   buildChartsLayout(environment)
        case .alan:     buildAlanLayout(environment)
        case .card:    buildStackLayout(environment)
        case .bottom:   buildTopLayout(environment)
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
        group.interItemSpacing = .flexible(8)

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

        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: UICollectionViewConstant.defaultInset,
            bottom: 0, trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }
}
