import Foundation

/// 탭바에서 같은 탭 재선택 시 최상단으로 스크롤하는 기능을 제공하는 프로토콜
protocol ScrollableToTop {
    /// 뷰를 최상단으로 스크롤합니다.
    func scrollToTop()
}
