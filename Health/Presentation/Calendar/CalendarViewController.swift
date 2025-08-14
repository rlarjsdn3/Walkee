import CoreData
import UIKit

final class CalendarViewController: CoreGradientViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    @Injected(.calendarViewModel) private var calendarVM: CalendarViewModel

    private lazy var scrollManager = CalendarScrollManager(calendarVM: calendarVM, collectionView: collectionView)

    /// 데이터 변경 이벤트 구독을 위한 Task
    private var dataChangesTask: Task<Void, Never>?

    override func setupAttribute() {
        super.setupAttribute()
		configureBackground()
        configureCollectionView()
        observeDataChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollManager.handleViewWillAppear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollManager.handleViewDidLayoutSubviews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 메모리 해제를 위한 Task 취소
        dataChangesTask?.cancel()
        dataChangesTask = nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        scrollManager.handleDeviceRotation(coordinator: coordinator)
    }
}

private extension CalendarViewController {

    func configureBackground() {
        applyBackgroundGradient(.midnightBlack)
    }

    func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = CalendarLayoutManager.createMainLayout()
        collectionView.register(
            CalendarMonthCell.nib,
            forCellWithReuseIdentifier: CalendarMonthCell.id
        )
    }

    // 뷰모델에서 전달받은 데이터 변경사항을 UI에 반영
    /// - Parameter changes: 변경 유형 (상단삽입, 하단삽입, 전체리로드)
    func handleDataChanges(_ changes: CalendarDataChanges) {
        switch changes {
            case .topInsert(let indexPaths):
                handleTopInsert(indexPaths: indexPaths)
            case .bottomInsert(let indexPaths):
                handleBottomInsert(indexPaths: indexPaths)
            case .reload:
                collectionView.reloadData()
        }
    }

    /// 상단에 새로운 월 데이터 삽입 시 UI 업데이트 및 스크롤 위치 보정
    /// - Parameter indexPaths: 삽입할 아이템들의 IndexPath 배열
    func handleTopInsert(indexPaths: [IndexPath]) {
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
                if shifted.item < self.collectionView.numberOfItems(inSection: shifted.section) {
                    self.collectionView.scrollToItem(at: shifted, at: .top, animated: false)
                }
            }
        }
    }

    /// 하단에 새로운 월 데이터 삽입 시 UI 업데이트
    /// - Parameter indexPaths: 삽입할 아이템들의 IndexPath 배열
    /// - Note: 하단 삽입은 현재 스크롤 위치에 영향을 주지 않으므로 별도 보정 불필요
    func handleBottomInsert(indexPaths: [IndexPath]) {
        collectionView.performBatchUpdates {
            collectionView.insertItems(at: indexPaths)
        }
    }

    /// Observable 패턴으로 데이터 변경 이벤트 구독
    func observeDataChanges() {
        dataChangesTask = Task { [weak self] in
            guard let self else { return }

            for await changes in self.calendarVM.dataChanges {
                // Task가 취소되었는지 확인
                guard !Task.isCancelled else { break }

                // 메인 액터에서 UI 업데이트 실행
                await MainActor.run {
                    self.handleDataChanges(changes)
                }
            }
        }
    }
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarVM.monthsCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarMonthCell.id, for: indexPath) as! CalendarMonthCell

        guard let monthData = calendarVM.month(at: indexPath.item) else { return cell }

        // 재사용 대비 토큰
        let token = UUID()
        cell.tag = token.hashValue

        Task { [weak self, weak cell] in
            guard let self else { return }
            let snapshots = await self.calendarVM.loadMonthSnapshots(year: monthData.year, month: monthData.month)

            // 여전히 같은 셀인가?
            guard let cell, cell.tag == token.hashValue else { return }

            await MainActor.run {
                cell.configure(with: monthData, snapshots: snapshots)
            }
        }

        return cell
    }
}

extension CalendarViewController: UICollectionViewDelegate {

    /// 스크롤 시 무한 스크롤 처리 (상단/하단 임계점 도달 시 추가 데이터 로드)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollManager.handleScrollForInfiniteLoading(scrollView)
    }
}
