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
        case walkingFilter
        case recommendPlace
        case loading
    }

    // 아이템 정의
    enum Item: Hashable {
        case weekSummaryItem
        case monthSummaryItem
        case aiSummaryItem
        case walkingFilterItem
        case recommendPlaceItem(WalkingCourse)
        case loadingItem(WalkingLoadingView.State)
    }
}

@MainActor
extension PersonalContent.Item {

    /// 컬렉션 뷰 셀 dequeue
    func dequeueReusableCollectionViewCell(
        collectionView: UICollectionView,
        weekSummaryCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        monthSummaryItemRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        aiSummaryItemRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        walkingFilterCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        recommendPlaceCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Void>,
        loadingCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, WalkingLoadingView.State>,
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
        case.aiSummaryItem:
            return collectionView.dequeueConfiguredReusableCell(
                using: weekSummaryCellRegistration,
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
        case .loadingItem(let state): // state를 추출
            return collectionView.dequeueConfiguredReusableCell(
                using: loadingCellRegistration,
                for: indexPath,
                item: state // state를 넣어야 함
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
        case .walkingFilter:
            return buildFilterLayout(environment)
        case .recommendPlace:
            // 이 부분을 list 생성자 대신 아래의 수동 레이아웃으로 교체합니다.
            return buildCardListLayout(environment)
        case .loading: // 추가
            return buildLoadingLayout(environment)
        }
    }

    /// 섹션 레이아웃 정의
    //주간 요약 레이아웃
    private func weekSummaryLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.effectiveContentSize.width
        let horizontalInset: CGFloat = UICollectionViewConstant.defaultInset

        // iPad 판단
        let isPad = environment.traitCollection.userInterfaceIdiom == .pad
        let isLandscape = containerWidth > environment.container.effectiveContentSize.height

        // iPad 방향에 따른 셀 개수 설정
        let itemsPerRow: CGFloat
        let interItemSpacing: CGFloat

        if isPad && isLandscape {
            // iPad 가로: 3개
            itemsPerRow = 3
            interItemSpacing = 16
        } else if isPad {
            // iPad 세로: 2개
            itemsPerRow = 2
            interItemSpacing = 10
        } else {
            // iPhone: 1개
            itemsPerRow = 1
            interItemSpacing = 0
        }

        let totalSpacing = horizontalInset * 2 + interItemSpacing * (itemsPerRow - 1)
        let itemWidth = (containerWidth - totalSpacing) / itemsPerRow

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .estimated(220)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(containerWidth - horizontalInset * 2),
            heightDimension: .estimated(220)
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
            top: 20,
            leading: horizontalInset,
            bottom: 20,
            trailing: horizontalInset
        )

        // 스크롤 설정 조정
        if isPad && isLandscape {
            // iPad 가로: 스크롤 불필요
            section.orthogonalScrollingBehavior = .none
        } else {
            // iPad 세로 & iPhone: 페이징 스크롤
            section.orthogonalScrollingBehavior = .groupPaging
        }

        return section
    }

//    private func buildHeaderLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
//        let itemSize = NSCollectionLayoutSize(
//            widthDimension: .fractionalWidth(1.0),
//            heightDimension: .estimated(80)
//        )
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//
//        let groupSize = NSCollectionLayoutSize(
//            widthDimension: .fractionalWidth(1.0),
//            heightDimension: .estimated(80)
//        )
//        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//
//        let section = NSCollectionLayoutSection(group: group)
//        section.contentInsets = NSDirectionalEdgeInsets(
//            top: 0,
//            leading: UICollectionViewConstant.defaultInset,
//            bottom: 0,
//            trailing: 0
//        )
//        return section
//    }

    //필터 버튼 레이아웃
    private func buildFilterLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {

        let buttonHeight: CGFloat = 30

        // 아이템이 전체 너비를 차지하도록 설정
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),  // 전체 너비 차지
            heightDimension: .absolute(buttonHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(buttonHeight)
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: 16, bottom: 0, trailing: 16
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

        if isPad {
            if isLandscape {
                columnsCount = 3     // iPad 가로: 2열
                horizontalSpacing = 16

            } else {
                columnsCount = 2     // iPad 세로: 2열
                horizontalSpacing = 16

            }
        } else {
            columnsCount = 1         // iPhone: 1열
            horizontalSpacing = 0

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
            top: -10,
            leading: UICollectionViewConstant.defaultInset,
            bottom: 20,
            trailing: UICollectionViewConstant.defaultInset
        )
        return section
    }

    private func buildLoadingLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200) // 충분한 높이
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 20,
            leading: UICollectionViewConstant.defaultInset,
            bottom: 20,
            trailing: UICollectionViewConstant.defaultInset
        )

        return section
    }
}
