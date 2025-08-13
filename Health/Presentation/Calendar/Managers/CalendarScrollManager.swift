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
            didFinishInitialScroll = true
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

    /// 스크롤 시 무한 스크롤을 처리합니다.
    ///
    /// 상단 또는 하단 임계점에 도달하면 추가 데이터를 비동기로 로드합니다.
    /// 초기 스크롤이 완료되기 전에는 무한 스크롤이 비활성화됩니다.
    ///
    /// - Parameter scrollView: 스크롤 이벤트가 발생한 스크롤뷰
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 초기 스크롤이 완료되기 전에는 무한 스크롤 비활성화
        guard didFinishInitialScroll else { return }

        let loadThreshold: CGFloat = 200
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        // 상단 근처 스크롤 시 과거 데이터 로드
        if offsetY < loadThreshold {
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

    /// 현재 월로 스크롤합니다.
    func scrollToCurrentMonth() {
        guard let collectionView = collectionView,
              let calendarVM,
              let indexPath = calendarVM.indexOfCurrentMonth() else {
            return
        }
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
    }
}
