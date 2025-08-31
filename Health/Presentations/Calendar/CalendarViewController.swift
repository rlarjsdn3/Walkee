import UIKit

import TSAlertController

final class CalendarViewController: HealthNavigationController, Alertable {

    @Injected private var healthService: (any HealthService)

    @IBOutlet weak var collectionView: UICollectionView!

    private let calendarVM = CalendarViewModel()
    private lazy var dataManager = CalendarDataManager(calendarVM: calendarVM, collectionView: collectionView)
    private lazy var scrollManager = CalendarScrollManager(calendarVM: calendarVM, collectionView: collectionView)

    /// 걸음 수 데이터 접근 권한 여부
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

    /// 현재 월로 스크롤하는 메서드
    ///
    /// 탭바의 캘린더 탭을 재선택했을 때 호출되어 현재 월로 부드럽게 스크롤합니다.
    func scrollToCurrentMonth() {
        guard isViewLoaded, collectionView != nil else { return }
        scrollManager.scrollToCurrentMonth(animated: true)
    }
}

// MARK: - Private Methods
private extension CalendarViewController {

    /// 알림 센터 옵저버를 설정합니다.
    ///
    /// 다음 알림들을 관찰합니다:
    /// - 앱이 포그라운드로 전환될 때
    /// - 걸음 수 데이터 동기화 완료
    /// - 목표 걸음 수 업데이트
    /// - 건강 앱 권한 상태 변경
    /// - 프로필에서 건강 연동 상태 변경
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

    /// 건강 앱 권한 상태를 확인하고 데이터를 다시 로드합니다.
    func updateAuthorizationAndReload() {
        Task {
            let result = await healthService.checkHasReadPermission(for: .stepCount)
            self.isStepCountAuthorized = result
            await MainActor.run {
                dataManager.reloadData()
            }
        }
    }

    /// 네비게이션 바를 구성합니다.
    ///
    /// 가이드 버튼과 현재 월로 스크롤하는 버튼을 추가하고,
    /// 타이틀과 아이콘을 설정합니다.
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

    /// 캘린더 사용법을 안내하는 가이드 화면을 표시합니다
    ///
    /// 걸음 수 확인, 대시보드 이동, 데이터 출처에 대한 정보를 제공합니다.
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

    /// 배경 그라데이션을 설정합니다.
    func configureBackground() {
        applyBackgroundGradient(.midnightBlack)
    }

    /// 컬렉션 뷰의 레이아웃과 셀 등록을 구성합니다.
    func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = CalendarLayoutManager.createMainLayout()
        collectionView.register(
            CalendarMonthCell.nib,
            forCellWithReuseIdentifier: CalendarMonthCell.id
        )
    }

    /// 특정 날짜의 대시보드 화면으로 이동합니다.
    ///
    /// - Parameter date: 이동할 대시보드의 기준 날짜
    ///
    /// 탭바 표시 문제를 방지하기 위해 push 전에 탭바를 미리 숨기며,
    /// pop 시 자동으로 복원됩니다.
    func navigationToDashboard(with date: Date) {
        let dashboardVC = DashboardViewController.instantiateInitialViewController(name: "Dashboard")
        dashboardVC.viewModel = DashboardViewModel(anchorDate: date, fromCalendar: true)

        // push 시 탭바가 잠깐 보였다 내려가는 문제로 미리 tabBar를 숨깁니다.
        // pop 해서 DashboardVC가 사라지면 다시 `hidesBottomBarWhenPushed = false`인 화면이 되므로
        // UITabBarController는 이 상태를 감지하고 탭바를 "자동으로 복원"해줍니다.
        // 그래서 따로 tabBar.isHidden = false 복원 코드를 작성할 필요가 없습니다.
        dashboardVC.hidesBottomBarWhenPushed = true
        tabBarController?.tabBar.isHidden = true
        navigationController?.pushViewController(dashboardVC, animated: true)
    }

    /// 앱이 포그라운드로 전환될 때 호출되는 메서드
    ///
    /// 건강 앱 권한 상태를 다시 확인하고 데이터를 업데이트합니다.
    @objc func handleWillEnterForeground() {
        Task {
            await refreshAuthorizationAndReload()
        }
    }

    /// 데이터 관련 알림을 처리하는 메서드
    ///
    /// 걸음 수 데이터 동기화나 목표 업데이트 시 호출되어 화면을 갱신합니다.
    @objc func handleDataNotification() {
        Task {
            reloadData()
        }
    }

    /// 건강 앱 관련 알림을 처리하는 메서드
    ///
    /// - Parameter notification: 건강 앱 권한 변경 또는 프로필 연동 상태 변경 알림
    ///
    /// 알림 종류에 따라 적절한 처리를 수행합니다:
    /// - `.didChangeHealthLinkStatusOnProfile`: 프로필에서 건강 연동 상태 변경
    /// - `.didChangeHKSharingAuthorizationStatus`: 건강 앱 권한 상태 변경
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

    /// 건강 앱 권한 상태를 새로고침하고 데이터를 다시 로드합니다.
    @MainActor
    func refreshAuthorizationAndReload() async {
        let status = await healthService.checkHasReadPermission(for: .stepCount)
        isStepCountAuthorized = status
        dataManager.reloadData()
    }

    /// 캘린더 데이터를 다시 로드합니다.
    @MainActor
    func reloadData() {
        dataManager.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension CalendarViewController: UICollectionViewDataSource {

    /// 컬렉션 뷰의 아이템 개수를 반환합니다.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarVM.monthsCount
    }

    /// 특정 인덱스 패스의 셀을 구성하고 반환합니다.
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

// MARK: - UICollectionViewDelegate
extension CalendarViewController: UICollectionViewDelegate {

    /// 스크롤 시 무한 스크롤을 처리합니다.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollManager.handleScrollForInfiniteLoading(scrollView)
    }

    /// 상단바 탭으로 인한 최상단 스크롤을 비활성화합니다.
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
}
