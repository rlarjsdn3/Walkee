//
//  PersonalContent.swift
//  Health
//
//  Created by juks86 on 8/5/25.
//

import UIKit

// 예시 데이터 모델 (실제 프로젝트에 맞게 수정)
//struct Place: Hashable {
//    let id = UUID() // 각 아이템을 고유하게 식별하기 위함
//    let name: String
//}

enum PersonalContent {

    // 섹션 정의
    enum Section: Hashable {
        case weekSummary
        case walkingHeader
        case walkingFilter
        case recommendPlace
    }

    // 아이템 정의
    enum Item: Hashable {
        case weekSummaryItem
        case monthSummaryItem
        case walkingHeaderItem
        case walkingFilterItem
        case recommendPlaceItem(WalkingCourse)
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
        recommendPlaceCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
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
        case .recommendPlaceItem:
            return collectionView.dequeueConfiguredReusableCell(
                using: recommendPlaceCellRegistration,
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
        case .recommendPlace:
            // 이 부분을 list 생성자 대신 아래의 수동 레이아웃으로 교체합니다.
            return buildCardListLayout(environment)
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
        let interItemSpacing: CGFloat = isPad ? 32 : 0

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
            bottom: 5,
            trailing: 0
        )
        return section
    }

    //필터 버튼 레이아웃
    private func buildFilterLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {

        let containerWidth = environment.container.effectiveContentSize.width
        let isPad = environment.traitCollection.userInterfaceIdiom == .pad
        let isLandscape = containerWidth > environment.container.effectiveContentSize.height

        let widthRatio: CGFloat

        if isPad { // 기기가 아이패드일 경우
            if isLandscape {
                // 아이패드 + 가로 모드
                widthRatio = 0.5
            } else {
                // 아이패드 + 세로 모드
                widthRatio = 0.7
            }
        } else { // 기기가 아이폰일 경우
            widthRatio = 0.9
        }

        // 위에서 결정된 비율에 따라 셀의 최종 너비를 pt단위로 계산합니다.
        let finalWidth = containerWidth * widthRatio

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(50)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // 그룹의 너비를 위에서 계산한 `finalWidth`의 절대값으로 고정합니다.
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(finalWidth),
            heightDimension: .estimated(50)
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

    // 카드 리스트 형태를 위한 새로운 레이아웃 함수
    private func buildCardListLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {

        let containerWidth = environment.container.effectiveContentSize.width
        let isPad = environment.traitCollection.userInterfaceIdiom == .pad
        let isLandscape = containerWidth > environment.container.effectiveContentSize.height

        // 아이패드 대응: 열 개수 설정
        let columnsCount: Int
        let horizontalSpacing: CGFloat
        let horizontalInset: CGFloat

        if isPad {
            if isLandscape {
                columnsCount = 2     // iPad 가로: 2열
                horizontalSpacing = 16
                horizontalInset = 32
            } else {
                columnsCount = 2     // iPad 세로: 2열
                horizontalSpacing = 16
                horizontalInset = 24
            }
        } else {
            columnsCount = 1         // iPhone: 1열
            horizontalSpacing = 0
            horizontalInset = 16
        }

        // 아이템 크기 설정
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columnsCount)),  // 열 개수에 따라 나누기
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // 그룹 크기 설정
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )

        let group: NSCollectionLayoutGroup
        if isPad {
            // iPad: 수평 그룹 (2열)
            group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: columnsCount
            )
            group.interItemSpacing = .fixed(horizontalSpacing)
        } else {
            // iPhone: 수직 그룹 (1열)
            group = NSCollectionLayoutGroup.vertical(
                layoutSize: groupSize,
                subitems: [item]
            )
        }

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12  // 각 그룹(행) 사이의 간격
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: UICollectionViewConstant.defaultInset,
            bottom: 0,
            trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }
}
