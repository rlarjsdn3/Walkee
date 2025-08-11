//
//  HomeContent.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

enum DashboardContent {

    enum Section: Hashable, Sendable {
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

    enum Item: Hashable, Sendable {
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
        /// 경고 텍스트 셀
        case text
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
        textCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Void>,
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

        case .text:
            return collectionView.dequeueConfiguredReusableCell(
                using: textCellRegistration,
                for: indexPath,
                item: ()
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
        case .alan, .card:
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: basicSupplementaryViewRegistration,
                for: indexPath
            )
        default:
            return nil
        }
    }

    func setContentConfiguration(
        basicSupplementaryView: inout UICollectionViewListCell,
        detailButton: UIButton
    ) {
        var config = basicSupplementaryView.defaultContentConfiguration()
        config.textProperties.font = .preferredFont(forTextStyle: .headline)
        config.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12, leading: 0,
            bottom: 12,trailing: 0
        )

        switch self {
        case .alan:
            config.text = "AI 요약 리포트"
            basicSupplementaryView.accessories = []
            basicSupplementaryView.contentConfiguration = config
        case .card:
            config.text = "보행 밸런스 분석"
            basicSupplementaryView.accessories = [.customView(configuration: .init(customView: detailButton, placement: .trailing()))]
            basicSupplementaryView.contentConfiguration = config
        default:
            return
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
        case .card:     buildCardLayout(environment)
        case .bottom:   buildTopLayout(environment)
        }
    }

    private func buildTopLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
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
        let leadingItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.65),
            heightDimension: .fractionalHeight(1.0)
        )
        let leadingItem = NSCollectionLayoutItem(layoutSize: leadingItemSize)

        let trailingItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(0.33)
        )
        let trailingItem = NSCollectionLayoutItem(layoutSize: trailingItemSize)

        let trailingGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.35),
            heightDimension: .fractionalHeight(1.0)
        )
        let trailingGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: trailingGroupSize,
            repeatingSubitem: trailingItem,
            count: 3
        )
        trailingGroup.interItemSpacing = .flexible(12)

        let nestedGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(225)

        )
        let nestedGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: nestedGroupSize,
            subitems: [leadingItem, trailingGroup]
        )
        nestedGroup.interItemSpacing = .flexible(8)

        let section = NSCollectionLayoutSection(group: nestedGroup)
        let defaultInset = UICollectionViewConstant.defaultInset
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 4,
            leading: defaultInset,
            bottom: 4,
            trailing: defaultInset
        )
        return section
    }

    private func buildChartsLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemWidthDimension: NSCollectionLayoutDimension = environment.orientation(
            iPhonePortrait: .fractionalWidth(1.0),
            iPadPortrait: .fractionalWidth(1.0),
            iPadLandscape: .fractionalWidth(0.5)
        )
        let itemSize = NSCollectionLayoutSize(
            widthDimension: itemWidthDimension,
            heightDimension: .absolute(300)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupWidthDimension: NSCollectionLayoutDimension = environment.orientation(
            iPhonePortrait: .fractionalWidth(0.9),
            iPadPortrait: .fractionalWidth(0.9),
            iPadLandscape: .fractionalWidth(1.0)
        )
        let groupSize = NSCollectionLayoutSize(
            widthDimension: groupWidthDimension,
            heightDimension: .absolute(300)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(12)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = UICollectionViewConstant.defaultInset
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: UICollectionViewConstant.defaultInset,
            bottom: 0, trailing: UICollectionViewConstant.defaultInset
        )
        section.orthogonalScrollingBehavior = environment.orientation(
            iPhonePortrait: .groupPaging,
            iPadPortrait: .groupPaging,
            iPadLandscape: .none
        )

        return section
    }

    private func buildAlanLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
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

    private func buildCardLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemWidthDimension: NSCollectionLayoutDimension = environment.horizontalSizeClass(
            compact: .fractionalWidth(1.0),
            regular: .fractionalWidth(0.25)
        )
        let itemSize = NSCollectionLayoutSize(
            widthDimension: itemWidthDimension,
            heightDimension: .estimated(200)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let subitems: [NSCollectionLayoutItem] = environment.horizontalSizeClass(
            compact: [item],
            regular: [item, item, item, item]
        )
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200) // TODO: - 레이아웃 재검토 및 수치 조정하기
        )
        let group: NSCollectionLayoutGroup = environment.horizontalSizeClass {
            NSCollectionLayoutGroup.vertical(
                layoutSize: groupSize,
                subitems: subitems
            )
        } regular: {
            NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: subitems
            )
        }()
        group.interItemSpacing = .flexible(12)

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

        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: UICollectionViewConstant.defaultInset,
            bottom: 0, trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }
}
