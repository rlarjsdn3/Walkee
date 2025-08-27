import UIKit

import TSAlertController

final class CalendarViewController: HealthNavigationController, Alertable {

    @Injected private var healthService: (any HealthService)

    @IBOutlet weak var collectionView: UICollectionView!

    private let calendarVM = CalendarViewModel()
    private lazy var dataManager = CalendarDataManager(calendarVM: calendarVM, collectionView: collectionView)
    private lazy var scrollManager = CalendarScrollManager(calendarVM: calendarVM, collectionView: collectionView)

    private var isStepCountAuthorized = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        updateAuthorizationAndReload()
        dataManager.startObserving()
    }

    override func setupAttribute() {
        super.setupAttribute()
        configureNavigationBar()
		configureBackground()
        configureCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollManager.handleViewDidLayoutSubviews()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // 회전 이벤트는 뷰컨트롤러가 화면에 표시되지 않아도 호출될 수 있음.
        // 앱 최초 실행 시에는 캘린더 탭을 열지 않은 상태에서도 이 메서드가 불리는데
        // 이 경우, scrollManager는 아직 초기화되지 않았기 때문에 강제 접근 시 crash 발생 가능
        // 따라서 "뷰가 이미 로드되고 실제 화면(window)에 표시된 경우"에만
        // scrollManager.handleDeviceRotation()을 호출하도록 제한.
        guard viewIfLoaded?.window != nil else { return }
        scrollManager.handleDeviceRotation(coordinator: coordinator)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 뷰 컨트롤러가 완전히 제거될 때
        if isMovingFromParent || isBeingDismissed {
            dataManager.stopObserving()
        }
    }

    // 캘린더 탭 재선택 시 현재 월로 스크롤
    func scrollToCurrentMonth() {
        guard isViewLoaded, collectionView != nil else { return }
        scrollManager.scrollToCurrentMonth(animated: true)
    }
}

private extension CalendarViewController {

    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataNotification),
            name: .didSyncStepData,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataNotification),
            name: .didUpdateGoalStepCount,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHealthNotification),
            name: .didChangeHKSharingAuthorizationStatus,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHealthNotification),
            name: .didChangeHealthLinkStatusOnProfile,
            object: nil
        )
    }

    func updateAuthorizationAndReload() {
        Task {
            let result = await healthService.checkHasReadPermission(for: .stepCount)
            self.isStepCountAuthorized = result
            await MainActor.run {
                dataManager.reloadData()
            }
        }
    }

    func configureNavigationBar() {
        let guideButton = HealthBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            primaryAction: { [weak self] in
                self?.showGuideView()
            }
        )

        let scrollToCurrentButton = HealthBarButtonItem(
            image: UIImage(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90"),
            primaryAction: { [weak self] in
                self?.scrollToCurrentMonth()
            }
        )

        healthNavigationBar.title = "캘린더"
        healthNavigationBar.titleImage = UIImage(systemName: "calendar")
        healthNavigationBar.trailingBarButtonItems = [guideButton, scrollToCurrentButton]
    }

    func showGuideView() {
        let sections = [
            GuideSection(
                title: "걸음 수 확인",
                description: "각 날짜 원에서 목표 대비 진행률을 확인할 수 있으며, 달성 시 색상으로 강조됩니다."
            ),
            GuideSection(
                title: "대시보드 이동",
                description: "데이터가 있는 날짜를 선택해서 열리는 대시보드를 통해 상세 정보를 확인할 수 있습니다."
            ),
            GuideSection(
                title: "데이터 출처",
                description: "걸음 수는 건강 앱과 동기화되며, 연동이 꺼져 있으면 표시되지 않습니다."
            )
        ]
        let guideView = GuideView.create(with: sections)

        showFloatingSheet(guideView) { _ in }
    }

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

    func navigationToDashboard(with date: Date) {
        let dashboardVC = DashboardViewController.instantiateInitialViewController(name: "Dashboard")
        dashboardVC.viewModel = DashboardViewModel(anchorDate: date)

        // push 시 탭바가 잠깐 보였다 내려가는 문제로 미리 tabBar를 숨깁니다.
        // pop 해서 DashboardVC가 사라지면 다시 `hidesBottomBarWhenPushed = false`인 화면이 되므로
        // UITabBarController는 이 상태를 감지하고 탭바를 "자동으로 복원"해줍니다.
        // 그래서 따로 tabBar.isHidden = false 복원 코드를 작성할 필요가 없습니다.
        dashboardVC.hidesBottomBarWhenPushed = true
        tabBarController?.tabBar.isHidden = true
        navigationController?.pushViewController(dashboardVC, animated: true)
    }

    @objc func handleWillEnterForeground() {
        Task {
            await refreshAuthorizationAndReload()
        }
    }

    @objc func handleDataNotification() {
        Task {
            reloadData()
        }
    }

    @objc func handleHealthNotification(_ notification: Notification) {
        Task { @MainActor in
            switch notification.name {
                // 프로필 탭에서 건강 연동 상태가 바뀌는 경우
                case .didChangeHealthLinkStatusOnProfile:
                    guard let status = notification.userInfo?[.status] as? Bool else { return }
                    isStepCountAuthorized = status
                    reloadData()

                // 건강 앱 연동 상태가 바뀌는 경우
                case .didChangeHKSharingAuthorizationStatus:
                    await refreshAuthorizationAndReload()

                default:
                    reloadData()
            }
        }
    }

    @MainActor
    func refreshAuthorizationAndReload() async {
        let status = await healthService.checkHasReadPermission(for: .stepCount)
        isStepCountAuthorized = status
        dataManager.reloadData()
    }

    @MainActor
    func reloadData() {
        dataManager.reloadData()
    }
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarVM.monthsCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarMonthCell.id, for: indexPath) as! CalendarMonthCell

        if let monthData = calendarVM.month(at: indexPath.item) {
            cell.configure(with: monthData, isStepCountAuthorized: isStepCountAuthorized)
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

    /// 스크롤 시 무한 스크롤 처리
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollManager.handleScrollForInfiniteLoading(scrollView)
    }

    /// 상단바를 탭해서 최상단으로 스크롤하는 동작 방지
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
}
