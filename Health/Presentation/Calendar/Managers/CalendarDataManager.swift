import UIKit

/// 달력 컬렉션뷰의 데이터 변경사항을 관리하는 매니저
@MainActor
final class CalendarDataManager {

    private let calendarVM: CalendarViewModel

    private weak var collectionView: UICollectionView?

    /// 데이터 변경 이벤트 구독을 위한 Task
    ///
    /// `startObserving()`에서 생성되고 `stopObserving()`에서 취소됩니다.
    /// Task가 실행 중일 때는 중복 시작을 방지합니다.
    private var dataChangesTask: Task<Void, Never>?

    init(calendarVM: CalendarViewModel, collectionView: UICollectionView) {
        self.calendarVM = calendarVM
        self.collectionView = collectionView
    }

    /// 데이터 변경사항 감지를 시작합니다.
    ///
    /// `CalendarViewModel.dataChanges` AsyncSequence를 구독하여
    /// 데이터 변경사항을 실시간으로 감지하고 UI에 반영합니다.
    ///
    /// - Important: 반드시 `stopObserving()`을 호출하여 리소스를 정리해야 합니다.
    func startObserving() {
        guard dataChangesTask == nil else { return }

        dataChangesTask = Task { [weak self] in
            guard let self else { return }

            for await changes in self.calendarVM.dataChanges {
                guard !Task.isCancelled else { break }
                self.handleDataChanges(changes)
            }
        }
    }

    /// 데이터 변경사항 감지를 중단합니다.
    ///
    /// 실행 중인 Task를 취소하고 리소스를 정리합니다.
    /// `deinit`에서 호출되어 메모리 누수를 방지합니다.
    func stopObserving() {
        dataChangesTask?.cancel()
        dataChangesTask = nil
    }

    /// 컬렉션뷰의 모든 데이터를 다시 로드합니다.
    func reloadData() {
        collectionView?.reloadData()
    }
}

private extension CalendarDataManager {

    /// 데이터 변경사항을 적절한 UI 업데이트로 변환합니다.
    ///
    /// - Parameter changes: 발생한 데이터 변경 유형
    ///
    /// 변경 유형에 따라 다음과 같이 처리됩니다:
    /// - `.topInsert`: 상단 삽입 + 스크롤 위치 보정
    /// - `.bottomInsert`: 하단 삽입 (위치 보정 불필요)
    /// - `.reload`: 전체 데이터 리로드
    func handleDataChanges(_ changes: CalendarDataChanges) {
        guard let collectionView else { return }

        switch changes {
            case .topInsert(let indexPaths):
                handleTopInsert(indexPaths: indexPaths, in: collectionView)
            case .bottomInsert(let indexPaths):
                handleBottomInsert(indexPaths: indexPaths, in: collectionView)
            case .reload:
                collectionView.reloadData()
        }
    }

    /// 상단에 새로운 월 데이터 삽입 시 UI 업데이트 및 스크롤 위치 보정을 수행합니다.
    ///
    /// - Parameters:
    ///   - indexPaths: 삽입할 아이템들의 IndexPath 배열
    ///   - collectionView: 업데이트할 컬렉션뷰
    ///
    /// - Important: 데이터 불일치나 보이는 아이템이 없는 경우 전체 리로드로 fallback 처리됩니다.
    func handleTopInsert(indexPaths: [IndexPath], in collectionView: UICollectionView) {
        // 현재 화면에 보이는 첫 번째 아이템의 위치 저장 (스크롤 위치 보정용)
        guard let firstVisible = collectionView.indexPathsForVisibleItems.min() else {
            // 보이는 아이템이 없으면 단순히 리로드
            collectionView.reloadData()
            return
        }

        // 데이터 정합성 확인
        let expectedItemCount = collectionView.numberOfItems(inSection: 0) + indexPaths.count
        guard expectedItemCount == calendarVM.monthsCount else {
            // 데이터 불일치 시 전체 리로드
            collectionView.reloadData()
            return
        }

        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: indexPaths)
            } completion: { _ in
                // 기존에 보던 아이템이 새로 삽입된 아이템 수만큼 뒤로 밀린 새 위치 계산
                let shifted = IndexPath(
                    item: firstVisible.item + indexPaths.count,
                    section: firstVisible.section
                )

                // 계산된 위치가 유효한지 확인 후 스크롤
                if shifted.item < collectionView.numberOfItems(inSection: shifted.section) {
                    collectionView.scrollToItem(at: shifted, at: .top, animated: false)
                }
            }
        }
    }

    /// 하단에 새로운 월 데이터 삽입 시 UI 업데이트를 수행합니다.
    ///
    /// - Parameters:
    ///   - indexPaths: 삽입할 아이템들의 IndexPath 배열
    ///   - collectionView: 업데이트할 컬렉션뷰
    ///
    /// 하단 삽입은 현재 스크롤 위치에 영향을 주지 않으므로,
    /// 별도의 스크롤 위치 보정이 필요하지 않습니다.
    func handleBottomInsert(indexPaths: [IndexPath], in collectionView: UICollectionView) {
        collectionView.performBatchUpdates {
            collectionView.insertItems(at: indexPaths)
        }
    }
}
