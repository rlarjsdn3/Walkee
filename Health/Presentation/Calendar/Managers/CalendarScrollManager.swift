import UIKit

/// 달력 컬렉션뷰의 스크롤 동작을 관리하는 매니저
@MainActor
final class CalendarScrollManager {

    private weak var calendarVM: CalendarViewModel?
    private weak var collectionView: UICollectionView?

    /// 첫 번째 스크롤(현재 월로 이동)을 완료했는지 여부
    ///
    /// 이 플래그는 앱 시작 시 한 번만 현재 월로 스크롤하도록 보장합니다.
    /// `handleViewDidLayoutSubviews()`에서 `true`로 설정됩니다.
    private(set) var didPerformInitialScroll = false

    /// 최초 스크롤이 안정적으로 끝나 무한 스크롤을 허용할 수 있는 상태인지 여부
    ///
    /// 초기 스크롤 직후에는 불안정한 상태이므로 무한 스크롤을 비활성화합니다.
    /// 0.1초 지연 후 `true`로 설정되어 무한 스크롤이 활성화됩니다.
    private(set) var isInitialScrollSettled = false

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
        guard !didPerformInitialScroll else { return }

        scrollToCurrentMonth()
        didPerformInitialScroll = true

        // 짧은 지연 후 무한 스크롤 활성화
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            await MainActor.run { self?.isInitialScrollSettled = true }
        }
    }

    /// 현재 월로 스크롤합니다.
    func scrollToCurrentMonth(animated: Bool = false) {
        guard let collectionView = collectionView,
              let calendarVM,
              let indexPath = calendarVM.indexOfCurrentMonth() else {
            return
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
    }

    /// 화면 회전 시 스크롤 위치를 처리합니다.
    ///
    /// 회전 전에 마지막으로 보았던 월의 정보를 저장하고,
    /// 회전 완료 후 동일한 월로 스크롤하여 사용자가 보고 있던 위치를 복원합니다.
    ///
    /// - Parameter coordinator: 화면 회전 트랜지션을 조정하는 코디네이터
    func handleDeviceRotation(coordinator: UIViewControllerTransitionCoordinator) {
        let lastSeenMonthData = getLastSeenMonthData()

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self,
                  let collectionView = self.collectionView,
                  let calendarVM = self.calendarVM else { return }

            DispatchQueue.main.async {
                self.scrollToSpecificMonth(lastSeenMonthData, in: collectionView, with: calendarVM)
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
        guard isInitialScrollSettled else { return }

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
    }

    /// 현재 화면에서 마지막으로 보인 월 데이터를 반환합니다.
    ///
    /// 화면에 완전히 보이는 셀 중에서 가장 상단 좌측에 위치한 셀의 월 데이터를 반환합니다.
    /// 완전히 보이는 셀이 없는 경우, 부분적으로라도 보이는 셀 중에서 선택합니다.
    ///
    /// - Returns: 현재 화면에서 보이는 월 데이터. 유효한 셀이 없는 경우 `nil`
    func getLastSeenMonthData() -> CalendarMonthData? {
        guard let collectionView,
              let calendarVM else { return nil }

        let screenArea = CGRect(
            x: 0,
            y: collectionView.contentOffset.y,
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )

        // 현재 보이는 indexPath들
        let indexPaths = collectionView.indexPathsForVisibleItems

        // 실제로 보이는 셀 + 월 데이터 추출
        let visibleCells: [VisibleCell] = indexPaths.compactMap { indexPath in
            guard indexPath.item >= 0 && indexPath.item < calendarVM.monthsCount,
                  let cell = collectionView.cellForItem(at: indexPath),
                  let monthData = calendarVM.month(at: indexPath.item) else { return nil }

            let overlap = screenArea.intersection(cell.frame)
            guard !overlap.isEmpty else { return nil }

            return VisibleCell(indexPath: indexPath, frame: cell.frame, monthData: monthData)
        }

        let fullyVisibleCells = visibleCells.filter { screenArea.contains($0.frame) }
        let topCell = fullyVisibleCells.min(by: isHigherOrMoreLeft)

        return topCell?.monthData ?? visibleCells.min(by: isHigherOrMoreLeft)?.monthData
    }

    /// 두 셀 중 더 높은 위치에 있거나 같은 높이에서 더 왼쪽에 있는 셀을 판단합니다.
    func isHigherOrMoreLeft(lhs: VisibleCell, rhs: VisibleCell) -> Bool {
        if lhs.frame.minY != rhs.frame.minY {
            return lhs.frame.minY < rhs.frame.minY
        }
        return lhs.frame.minX < rhs.frame.minX
    }

    /// 지정된 월 데이터에 해당하는 위치로 스크롤합니다.
    ///
    /// 주어진 월 데이터와 일치하는 월을 찾아 해당 위치로 스크롤합니다.
    /// 일치하는 월을 찾을 수 없는 경우 현재 월로 스크롤하여 fallback을 제공합니다.
    ///
    /// - Parameters:
    ///   - monthData: 스크롤할 대상 월 데이터
    ///   - collectionView: 스크롤을 수행할 컬렉션뷰
    ///   - calendarVM: 월 데이터를 제공하는 뷰모델
    func scrollToSpecificMonth(
        _ monthData: CalendarMonthData?,
        in collectionView: UICollectionView,
        with calendarVM: CalendarViewModel
    ) {
        if let monthData,
           let index = calendarVM.months.firstIndex(where: { $0.year == monthData.year && $0.month == monthData.month }) {
            // 기억해둔 월로 스크롤하여 위치 복원
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        } else {
            // 기억해둔 월이 없거나 잘못된 경우 현재 월로 이동 (fallback)
            scrollToCurrentMonth()
        }
    }
}
