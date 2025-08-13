import UIKit

/// 달력 컬렉션뷰의 레이아웃 생성을 담당하는 매니저
@MainActor
final class CalendarLayoutManager {
    
    /// 메인 달력 컬렉션뷰의 레이아웃을 생성합니다.
    ///
    /// 화면 크기와 기기 특성에 따라 1열, 2열, 또는 3열 레이아웃으로 구성됩니다.
    /// - iPhone: 1열
    /// - iPad 세로: 2열
    /// - iPad 가로: 3열
    /// 각 월 셀의 높이는 헤더, 요일, 날짜 영역을 모두 포함하여 계산됩니다.
    ///
    /// - Returns: 메인 달력용 `UICollectionViewLayout` 인스턴스
    static func createMainLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, env in
            let columns = determineColumnCount(for: env)

            // 섹션 및 아이템 간격 설정
            let sectionInset = UICollectionViewConstant.defaultInset
            let itemInset = UICollectionViewConstant.defaultItemInset

            // 각 열의 가용 너비 계산
            let totalWidth = env.container.effectiveContentSize.width
            let totalItemInset = itemInset * (columns - 1)
            let availableWidth = totalWidth - (sectionInset * 2) - totalItemInset
            let columnWidth = availableWidth / columns

            // 월 셀의 높이 계산 (헤더 + 요일 + 날짜 영역)
            let headerHeight: CGFloat = 28
            let weekdayHeight: CGFloat = 20
            let verticalSpacing: CGFloat = 16 * 2
            let daySize: CGFloat = columnWidth / 7.0
            let numberOfRows: CGFloat = 6 // 고정
            let monthCellHeight = headerHeight + weekdayHeight + verticalSpacing + daySize * numberOfRows

            // 아이템 크기 설정 (너비는 비율, 높이는 절대값)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / columns),
                heightDimension: .absolute(monthCellHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // 그룹 크기 설정 (전체 너비, 계산된 높이)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(monthCellHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: Array(repeating: item, count: Int(columns))
            )
            group.interItemSpacing = .fixed(itemInset)

            // 섹션 설정 (여백 및 그룹 간 간격)
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: sectionInset,
                leading: sectionInset,
                bottom: sectionInset,
                trailing: sectionInset
            )
            section.interGroupSpacing = 50
            return section
        }
    }

    /// 월별 날짜 컬렉션뷰의 레이아웃을 생성합니다.
    ///
    /// `CalendarMonthCell` 내부에서 사용되는 7×6 그리드 레이아웃을 생성합니다.
    /// 각 날짜 셀은 정사각형 모양으로 표시됩니다.
    ///
    /// - Returns: 날짜 그리드용 `UICollectionViewLayout` 인스턴스
    static func createDateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 7.0),
            heightDimension: .fractionalWidth(1.0 / 7.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / 7.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: Array(repeating: item, count: 7)
        )

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

private extension CalendarLayoutManager {

    /// 환경에 따라 컬럼 수를 결정합니다.
    /// - Parameter env: 컬렉션뷰 레이아웃 환경
    /// - Returns: 표시할 컬럼 수 (1, 2, 또는 3)
    static func determineColumnCount(for env: NSCollectionLayoutEnvironment) -> CGFloat {
        let containerWidth = env.container.effectiveContentSize.width
        let containerHeight = env.container.effectiveContentSize.height
        let idiom = UIDevice.current.userInterfaceIdiom

        guard idiom == .pad else {
            return 1
        }

        let isLandscape = containerWidth > containerHeight
        return isLandscape ? 3 : 2
    }
}
