import UIKit

final class CalendarViewController: CoreGradientViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private let calendarVM = CalendarViewModel()
    private lazy var scrollManager = CalendarScrollManager(calendarVM: calendarVM, collectionView: collectionView)

    /// 데이터 변경 이벤트 구독을 위한 Task
    private var dataChangesTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadCalendar),
            name: .stepDataDidSync,
            object: nil
        )
    }

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

    func navigationToDashboard(with date: Date) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let dashboardVC = storyboard.instantiateViewController(identifier: DashboardViewController.id) { coder in
            DashboardViewController(date: date, coder: coder)
        }

        // push 시 탭바가 잠깐 보였다 내려가는 문제로 미리 tabBar를 숨깁니다.
        // pop 해서 DashboardVC가 사라지면 다시 `hidesBottomBarWhenPushed = false`인 화면이 되므로
        // UITabBarController는 이 상태를 감지하고 탭바를 "자동으로 복원"해줍니다.
        // 그래서 따로 tabBar.isHidden = false 복원 코드를 작성할 필요가 없습니다.
        dashboardVC.hidesBottomBarWhenPushed = true
        tabBarController?.tabBar.isHidden = true
        navigationController?.pushViewController(dashboardVC, animated: true)

    }

    @objc func reloadCalendar() {
        collectionView.reloadData()
    }
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarVM.monthsCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarMonthCell.id, for: indexPath) as! CalendarMonthCell

        if let monthData = calendarVM.month(at: indexPath.item) {
            cell.configure(with: monthData)
        }

        if cell.onDateSelected == nil {
            cell.onDateSelected = { [weak self] date in
                self?.navigationToDashboard(with: date)
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
