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
        case weekSummary
        case walkingHeader
        case walkingFilter
    }

    // 아이템 정의
    enum Item: Hashable {
        case weekSummaryItem
        case monthSummaryItem
        case walkingHeaderItem
        case walkingFilterItem

    }
}

@MainActor
extension PersonalContent.Item {

    /// 컬렉션 뷰 셀 dequeue
    func dequeueReusableCollectionViewCell(
        collectionView: UICollectionView,
        weekSummaryCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        monthSummaryItemRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        walkigHeaderCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        walkingFilterCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch self {
        case.monthSummaryItem:
            return collectionView.dequeueConfiguredReusableCell(
                using: monthSummaryItemRegistration,
                for: indexPath,
                item: ()
            )
        case.weekSummaryItem:
            return collectionView.dequeueConfiguredReusableCell(
                using: weekSummaryCellRegistration,
                for: indexPath,
                item: ()
            )
        case.walkingHeaderItem:
            return collectionView.dequeueConfiguredReusableCell(
                using: walkigHeaderCellRegistration,
                for: indexPath,
                item: ()
            )
        case.walkingFilterItem:
            return collectionView.dequeueConfiguredReusableCell(
                using: walkingFilterCellRegistration,
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
        case .weekSummary:
            return weekSummaryLayout(environment)
        case .walkingHeader:
            return buildHeaderLayout(environment)
        case .walkingFilter:
            return buildFilterLayout(environment)
        }
    }

    /// 섹션 레이아웃 정의
    //주간 요약 레이아웃
    private func weekSummaryLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.effectiveContentSize.width
        let horizontalInset: CGFloat = UICollectionViewConstant.defaultInset

        // iPad 판단
        let isPad = environment.traitCollection.userInterfaceIdiom == .pad

        // iPad일 경우 2개 보이도록 설정
        let itemsPerRow: CGFloat = isPad ? 2 : 1
        let interItemSpacing: CGFloat = isPad ? 10 : 0

        let totalSpacing = horizontalInset * 2 + interItemSpacing * (itemsPerRow - 1)
        let itemWidth = (containerWidth - totalSpacing) / itemsPerRow

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .estimated(350)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(containerWidth - horizontalInset * 2),
            heightDimension: .estimated(350)
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: Int(itemsPerRow)
        )
        group.interItemSpacing = .fixed(interItemSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: horizontalInset,
            bottom: 20,
            trailing: horizontalInset
        )

        // iPad는 스크롤만, iPhone은 groupPaging
        section.orthogonalScrollingBehavior = isPad ? .continuous : .groupPaging

        return section
    }

    private func buildHeaderLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(60)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(60)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: UICollectionViewConstant.defaultInset,
            bottom: 10,
            trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }

    //필터 버튼 레이아웃
    private func buildFilterLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.8),
            heightDimension: .estimated(35)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.8),
            heightDimension: .estimated(35)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

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
