import UIKit

import TSAlertController

final class CalendarViewController: HealthNavigationController, Alertable {

    @IBOutlet weak var collectionView: UICollectionView!

    /// 뷰가 나타날 때 현재 월로 스크롤할지 여부를 결정하는 플래그
    ///
    /// 탭 전환 시(`true`)와 화면 내 네비게이션(`false`) 시나리오를 구분하여 적절한 스크롤 동작을 제어합니다.
    /// `viewWillAppear(_:)`에서 사용된 후 자동으로 `false`로 리셋되어 일회성 동작을 보장합니다.
    ///
    /// - Note: 다른 탭에서 달력 탭으로 전환할 때만 `true`로 설정하고, 달력 내 push/pop 시에는 기본값(`false`)을 유지합니다.
    var shouldScrollToCurrentOnAppear = false

    private let calendarVM = CalendarViewModel()
    private lazy var dataManager = CalendarDataManager(calendarVM: calendarVM, collectionView: collectionView)
    private lazy var scrollManager = CalendarScrollManager(calendarVM: calendarVM, collectionView: collectionView)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        dataManager.startObserving()
    }

    override func setupAttribute() {
        super.setupAttribute()
        configureNavigationBar()
		configureBackground()
        configureCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollManager.handleViewWillAppear(shouldScrollToCurrentOnAppear)
        shouldScrollToCurrentOnAppear = false // 기본값으로 복원
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

    deinit {
        MainActor.assumeIsolated {
            dataManager.stopObserving()
        }
    }
}

private extension CalendarViewController {

    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadCalendar),
            name: .stepDataDidSync,
            object: nil
        )
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
                self?.scrollManager.scrollToCurrentMonth(animated: true)
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

    @objc func reloadCalendar() {
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

    /// 스크롤 시 무한 스크롤 처리
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollManager.handleScrollForInfiniteLoading(scrollView)
    }

    /// 상단바를 탭해서 최상단으로 스크롤하는 동작 방지
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
}
