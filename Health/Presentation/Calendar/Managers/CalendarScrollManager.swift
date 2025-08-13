import UIKit

/// 달력 컬렉션뷰의 스크롤 동작을 관리하는 매니저
@MainActor
final class CalendarScrollManager {

    private weak var calendarVM: CalendarViewModel?
    private weak var collectionView: UICollectionView?

    /// 첫 번째 스크롤(현재 월로 이동) 완료 여부
    private(set) var didScrollToCurrent = false

    /// 초기 스크롤이 완전히 완료되었는지 여부 (무한 스크롤 허용 조건)
    private(set) var didFinishInitialScroll = false

    /// 마지막으로 상단 로드를 요청한 시간
    private var lastTopLoadTime: Date?

    init(calendarVM: CalendarViewModel, collectionView: UICollectionView) {
        self.calendarVM = calendarVM
        self.collectionView = collectionView
    }

    /// `viewDidLayoutSubviews`에서 호출되는 메서드
    ///
    /// 최초 1회만 현재 월로 스크롤하고 무한 스크롤을 활성화합니다.
    /// 레이아웃이 완전히 설정된 후에 호출되어야 정확한 스크롤 위치를 계산할 수 있습니다.
    func handleViewDidLayoutSubviews() {
        if !didScrollToCurrent {
            scrollToCurrentMonth()
            didScrollToCurrent = true

            // 초기에 현재 월로 스크롤 완료 후 짧은 지연을 두고 무한 스크롤 활성화
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                await MainActor.run { self?.didFinishInitialScroll = true }
            }
        }
    }

    /// `viewWillAppear`에서 호출되는 메서드
    ///
    /// 이미 초기 스크롤을 한 상태에서만 현재 월 위치를 재조정합니다.
    /// 다른 화면에서 돌아왔을 때 현재 월이 제대로 표시되도록 보장합니다.
    func handleViewWillAppear() {
        if didScrollToCurrent {
            scrollToCurrentMonth()
        }
    }

    /// 화면 회전 시 스크롤 위치를 처리합니다.
    func handleDeviceRotation(coordinator: UIViewControllerTransitionCoordinator) {
        // 회전 전 현재 화면 최상단에 보이는 월을 기억
        let currentTopMonthIndexPath = findTopMostVisibleIndexPath()

        // 화면 회전과 동시에 레이아웃 변경 및 위치 복원
        coordinator.animate(alongsideTransition: { context in
            guard let collectionView = self.collectionView else { return }

            let newLayout = CalendarLayoutManager.createMainLayout()
            collectionView.setCollectionViewLayout(newLayout, animated: false)
            collectionView.layoutIfNeeded()

            // 기억해둔 월로 스크롤하여 위치 복원
            if let indexPath = currentTopMonthIndexPath {
                collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        })
    }

    /// 스크롤 시 무한 스크롤을 처리합니다.
    ///
    /// 상단 또는 하단 임계점에 도달하면 추가 데이터를 비동기로 로드합니다.
    /// 초기 스크롤이 완료되기 전에는 무한 스크롤이 비활성화됩니다.
    ///
    /// - Parameter scrollView: 스크롤 이벤트가 발생한 스크롤뷰
    func handleScrollForInfiniteLoading(_ scrollView: UIScrollView) {
        // 초기 스크롤이 완료되기 전에는 무한 스크롤 비활성화
        guard didFinishInitialScroll else { return }

        let loadThreshold: CGFloat = 200
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        // 상단 근처 스크롤 시 과거 데이터 로드
        if offsetY < loadThreshold {
            // 1초 이내 중복 요청 방지
            let now = Date()
            if let lastTime = lastTopLoadTime, now.timeIntervalSince(lastTime) < 1.0 { return }
            lastTopLoadTime = now

            Task {
                await calendarVM?.loadMoreTop()
            }
        }

        // 하단 근처 스크롤 시 미래 데이터 로드
        if offsetY > contentHeight - visibleHeight - loadThreshold {
            Task {
                await calendarVM?.loadMoreBottom()
            }
        }
    }
}

private extension CalendarScrollManager {

    /// 화면에 실제로 보이는 셀의 정보를 담는 구조체
    struct VisibleCell {
        let indexPath: IndexPath
        let frame: CGRect
        let monthData: CalendarMonthData

        /// 화면 상단으로부터의 거리를 계산합니다.
        func distanceFromScreenTop(_ screenArea: CGRect) -> CGFloat {
            return abs(frame.minY - screenArea.minY)
        }
    }

    /// 현재 월로 스크롤합니다.
    func scrollToCurrentMonth() {
        guard let collectionView = collectionView,
              let calendarVM,
              let indexPath = calendarVM.indexOfCurrentMonth() else {
            return
        }
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
    }

    /// 현재 화면에서 가장 위에 보이는 월의 IndexPath를 찾습니다.
    ///
    /// **문제점**: `indexPathsForVisibleItems`가 때로 화면에 보이지 않는 잘못된 셀(예: 0번)을 포함
    /// **해결책**: 실제 화면 영역과 교집합이 있는 셀만 필터링 후 최상단 선택
    ///
    /// - Returns: 화면 최상단 월의 IndexPath, 없으면 nil
    private func findTopMostVisibleIndexPath() -> IndexPath? {
        guard let collectionView, let calendarVM else { return nil }

        // 현재 사용자가 보고 있는 화면 영역 계산
        let currentScreenArea = CGRect(
            x: 0,
            y: collectionView.contentOffset.y,
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )

        // CollectionView가 제공하는 "보이는 셀" 목록 가져오기
        // 주의: 이 목록에는 실제로는 화면에 보이지 않는 잘못된 셀이 포함될 수 있음
        let potentiallyVisibleIndexPaths = collectionView.indexPathsForVisibleItems

        // 실제로 화면에 보이는 유효한 셀들만 걸러내기
        let actuallyVisibleCells = potentiallyVisibleIndexPaths.compactMap { indexPath -> VisibleCell? in

            // 기본 유효성 검사
            guard indexPath.item >= 0 && indexPath.item < calendarVM.monthsCount else {
                // 인덱스가 데이터 범위를 벗어나면 무시
                return nil
            }
            guard let cell = collectionView.cellForItem(at: indexPath) else {
                // 실제 셀이 존재하지 않으면 무시
                return nil
            }
            guard let monthData = calendarVM.month(at: indexPath.item) else {
                // 월 데이터가 없으면 무시
                return nil
            }

            // 실제 화면에 보이는지 확인
            let cellFrame = cell.frame
            let overlappingArea = currentScreenArea.intersection(cellFrame)

            if overlappingArea.isEmpty {
                // 셀이 화면과 전혀 겹치지 않으면 제외 (예: 0번 셀)
                return nil
            }

            return VisibleCell(
                indexPath: indexPath,
                frame: cellFrame,
                monthData: monthData
            )
        }

        // 유효한 셀들 중에서 화면 최상단에 가장 가까운 셀 찾기
        let topMostVisibleCell = actuallyVisibleCells.min { cell1, cell2 in
            // 각 셀이 화면 상단에서 얼마나 떨어져 있는지 계산
            let distance1 = cell1.distanceFromScreenTop(currentScreenArea)
            let distance2 = cell2.distanceFromScreenTop(currentScreenArea)

            // 거리가 더 짧은(화면 상단에 더 가까운) 셀을 선택
            return distance1 < distance2
        }

        // 찾은 셀의 IndexPath 반환
        if let topCell = topMostVisibleCell {
            return topCell.indexPath
        }

        // Fallback - 위 방법이 실패하면 화면 상단 중앙 지점에서 직접 찾기
        let screenTopCenterPoint = CGPoint(
            x: currentScreenArea.midX,
            y: currentScreenArea.minY + 50 // 화면 상단에서 50pt 아래 (여백 고려)
        )

        return collectionView.indexPathForItem(at: screenTopCenterPoint)
    }
}
