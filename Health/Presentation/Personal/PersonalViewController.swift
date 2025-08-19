//
//  PersonalViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/1/25.
//
import UIKit
import CoreLocation
import TSAlertController

class PersonalViewController: CoreGradientViewController, Alertable {

    typealias PersonalDiffableDataSource = UICollectionViewDiffableDataSource<PersonalContent.Section, PersonalContent.Item>

    @IBOutlet weak var collectionView: UICollectionView!
    @Injected private var promptBuilderService: (any PromptBuilderService)
    private var dataSource: PersonalDiffableDataSource?
    private var courses: [WalkingCourse] = [] //실제 표시되는 코스 데이터
    private var allCourses: [WalkingCourse] = [] // 전체 코스 데이터
    private var easyLevelCourses: [WalkingCourse] = []    // "1" 난이도 코스들
    private var mediumLevelCourses: [WalkingCourse] = []  // "2" 난이도 코스들
    private var hardLevelCourses: [WalkingCourse] = []    // "3" 난이도 코스들
    private var llmRecommendedLevels: [String] = []  //	Alan에게 받아올 난이도(추후 작업 예정)
    private var currentSortType: String = "코스길이순" //기본 정렬
    private var networkService = DefaultNetworkService()

    private var distanceViewModel = CourseDistanceViewModel()
    private var previousLocationPermission = false  // 이전 권한 상태 추적

    override func initVM() { }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        setupDistanceViewModel()
        applyInitialSnapshot()
        previousLocationPermission = LocationPermissionService.shared.checkCurrentPermissionStatus()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkLocationPermissionChange),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        Task { @MainActor in
            await requestInitialLocationPermission()
            loadInitialCourses()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // 앱이 포그라운드로 돌아올 때마다 권한 상태 확인
        checkLocationPermissionChange()
    }

    override func setupAttribute() {
        super.setupAttribute()
        collectionView.backgroundColor = .clear
        applyBackgroundGradient(.midnightBlack)
        collectionView.delegate = self
        collectionView.setCollectionViewLayout(createCollectionViewLayout(), animated: false)
    }

    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { [weak self] sectionIndex, environment in
            guard let section = self?.dataSource?.sectionIdentifier(for: sectionIndex) else { return nil }
            return section.buildLayout(environment)
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 16
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: config)
    }

    private func weekSummaryCellRegistration() -> UICollectionView.CellRegistration<WeekSummaryCell, Void> {
        UICollectionView.CellRegistration<WeekSummaryCell, Void>(cellNib: WeekSummaryCell.nib) { cell, indexPath, _ in
        }
    }

    private func monthSummaryCellRegistration() -> UICollectionView.CellRegistration<MonthSummaryCell, Void> {
        UICollectionView.CellRegistration<MonthSummaryCell, Void>(cellNib: MonthSummaryCell.nib) { cell, indexPath, _ in
            // MonthSummaryCell 셀 설정
        }
    }

    private func aiSummaryCellRegistration() -> UICollectionView.CellRegistration<AISummaryCell, Void> {
        UICollectionView.CellRegistration<AISummaryCell, Void>(cellNib: AISummaryCell.nib) { cell, indexPath, _ in
            let itemID = AIMonthlySummaryCellViewModel.ItemID()
            let viewModel = AIMonthlySummaryCellViewModel(itemID: itemID)

            cell.configure(with: viewModel, promptBuilderService: self.promptBuilderService)
        }
    }

    private func createWalkingHeaderRegistration() -> UICollectionView.CellRegistration<WalkingHeaderCell, Void> {
        UICollectionView.CellRegistration<WalkingHeaderCell, Void>(cellNib: WalkingHeaderCell.nib) { cell, indexPath, _ in
            // WalkingHeaderCell 셀 설정
        }
    }

    private func createWalkingFilterRegistration() -> UICollectionView.CellRegistration<WalkingFilterCell, Void> {
        UICollectionView.CellRegistration<WalkingFilterCell, Void>(cellNib: WalkingFilterCell.nib) { cell, indexPath, _ in
            // 필터 선택 시 실행될 클로저 설정
            cell.onFilterSelected = { [weak self] selectedFilter in
                // 어떤 필터가 눌리든 applySorting 함수를 호출하도록 단순화
                self?.applySorting(sortType: selectedFilter)
            }
        }
    }

    private func createRecommendPlaceCellRegistration() -> UICollectionView.CellRegistration<RecommendPlaceCell, WalkingCourse> {
        UICollectionView.CellRegistration<RecommendPlaceCell, WalkingCourse>(cellNib: RecommendPlaceCell.nib) { [weak self] cell, indexPath, course in
            // 기본 설정
            cell.configure(with: course)

            //뷰모델에서 캐시된 거리 확인 후 설정
            if let distanceText = self?.distanceViewModel.getCachedDistance(for: course.gpxpath) {
                // 이미 계산된 결과가 있으면 바로 표시 (에러 메시지 포함)
                cell.updateDistance(distanceText)
            } else {
                // 캐시된 결과가 없을 때만 로딩 상태
                cell.updateDistance("거리측정중...")
            }
        }
    }

    private func setupDataSource() {
        let weekSummaryRegistration = weekSummaryCellRegistration()
        let monthSummaryRegistration = monthSummaryCellRegistration()
        let aiSummaryCellRegistration = aiSummaryCellRegistration()
        let walkingHeaderRegistration = createWalkingHeaderRegistration()
        let walkingFilterRegistration = createWalkingFilterRegistration()
        let recommendPlaceRegistration = createRecommendPlaceCellRegistration()

        dataSource = PersonalDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .weekSummaryItem:
                return collectionView.dequeueConfiguredReusableCell(using: weekSummaryRegistration, for: indexPath, item: ())
            case .walkingHeaderItem:
                return collectionView.dequeueConfiguredReusableCell(using: walkingHeaderRegistration, for: indexPath, item: ())
            case .walkingFilterItem:
                return collectionView.dequeueConfiguredReusableCell(using: walkingFilterRegistration, for: indexPath, item: ())
            case .monthSummaryItem:
                return collectionView.dequeueConfiguredReusableCell(using: monthSummaryRegistration, for: indexPath, item: ())
            case .aiSummaryItem:
                return collectionView.dequeueConfiguredReusableCell(using: aiSummaryCellRegistration, for: indexPath, item: ())
            case .recommendPlaceItem(let course):
                return collectionView.dequeueConfiguredReusableCell(using: recommendPlaceRegistration, for: indexPath, item: course)
            }
        }
    }

    // MARK: - Snapshot Methods
    // 초기 스냅샷 (데이터 로드 전)
    private func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<PersonalContent.Section, PersonalContent.Item>()
        snapshot.appendSections([.weekSummary, .walkingHeader, .walkingFilter])
        snapshot.appendItems([.weekSummaryItem, .monthSummaryItem, .aiSummaryItem], toSection: .weekSummary)
        snapshot.appendItems([.walkingHeaderItem], toSection: .walkingHeader)
        snapshot.appendItems([.walkingFilterItem], toSection: .walkingFilter)
        // recommendPlace 섹션은 아직 추가하지 않음 (데이터가 없으므로)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    // 데이터 로드 후 스냅샷
    private func applyDataSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<PersonalContent.Section, PersonalContent.Item>()

        // 모든 섹션 추가
        snapshot.appendSections([.weekSummary, .walkingHeader, .walkingFilter, .recommendPlace])
        snapshot.appendItems([.weekSummaryItem, .monthSummaryItem, .aiSummaryItem], toSection: .weekSummary)
        snapshot.appendItems([.walkingHeaderItem], toSection: .walkingHeader)
        snapshot.appendItems([.walkingFilterItem], toSection: .walkingFilter)

        // 실제 코스 데이터 추가
        let courseItems = courses.map { PersonalContent.Item.recommendPlaceItem($0) }
        snapshot.appendItems(courseItems, toSection: .recommendPlace)

        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    // 전체 코스를 난이도별로 나누는 메서드
    private func separateCoursesByDifficulty() {
        // 배열들 초기화
        easyLevelCourses.removeAll()
        mediumLevelCourses.removeAll()
        hardLevelCourses.removeAll()
        // 중복 제거를 위한 Set 사용
        var addedCourseNames: Set<String> = []

        // 전체 코스를 순회하면서 난이도별로 분류 (중복 제거)
        for course in allCourses {

            // 이미 추가된 코스인지 확인
            if addedCourseNames.contains(course.crsKorNm) {
                continue
            }

            // 새로운 코스라면 Set에 추가
            addedCourseNames.insert(course.crsKorNm)

            switch course.crsLevel {
            case "1":
                easyLevelCourses.append(course)
            case "2":
                mediumLevelCourses.append(course)
            case "3":
                hardLevelCourses.append(course)
            default:
              break
            }
        }

        // 각 배열을 랜덤하게 섞기
        easyLevelCourses.shuffle()
        mediumLevelCourses.shuffle()
        hardLevelCourses.shuffle()
    }

    @MainActor
    private func loadInitialCourses() {
        allCourses = WalkingCourseService.shared.loadWalkingCourses()
        separateCoursesByDifficulty()

        if easyLevelCourses.count > 5 {
            courses = Array(easyLevelCourses.prefix(5))
        } else {
            courses = easyLevelCourses
        }

        applySorting(sortType: self.currentSortType)

        // 거리 계산을 시작하고 끝날 때까지 기다림
        Task {
            await distanceViewModel.prepareAndCalculateDistances(for: self.courses)
        }
    }

    // 위치 권한 변경 감지 및 자동 재계산
    @objc private func checkLocationPermissionChange() {
        let currentPermission = LocationPermissionService.shared.checkCurrentPermissionStatus()

        // 권한 상태가 '변경'되었다면 무조건 동작
        if previousLocationPermission != currentPermission {
            // 현재 상태를 먼저 저장하여 중복 실행 방지
            previousLocationPermission = currentPermission

            Task { @MainActor in
                distanceViewModel.clearDistanceCache()
                applyDataSnapshot()
                // 거리 계산을 다시 요청합니다. (권한 없으면 "위치 권한 없음"이 캐시에 저장됨)
                await distanceViewModel.prepareAndCalculateDistances(for: self.courses)
                // 계산이 끝난 후, 최종 결과("위치 권한 없음")를 표시하기 위해 UI를 다시 갱신합니다.
                applyDataSnapshot()
            }
        }
    }

    private func updateCellDistance(gpxURL: String, distanceText: String) {
        // courses 배열에서 해당 gpxURL을 가진 코스의 인덱스를 찾습니다.
        guard let index = courses.firstIndex(where: { $0.gpxpath == gpxURL }) else { return }

        // 해당 인덱스로 IndexPath를 만듭니다.
        let indexPath = IndexPath(item: index, section: 3)

        // 현재 화면에 보이는 셀이라면 즉시 업데이트합니다.
        if let cell = collectionView.cellForItem(at: indexPath) as? RecommendPlaceCell {
            cell.updateDistance(distanceText)
        }
    }

    private func setupDistanceViewModel() {
        distanceViewModel.onCacheNeedsRefresh = { [weak self] in
            self?.applyDataSnapshot()
        }

        distanceViewModel.onDistanceUpdated = { [weak self] gpxURL, distanceText in
            self?.updateCellDistance(gpxURL: gpxURL, distanceText: distanceText)
        }
    }

    // 메모리 해제 시 옵저버 제거
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // GPX URL로 IndexPath 찾기
    private func findIndexPath(for gpxURL: String) -> IndexPath? {
        for (index, course) in courses.enumerated() {
            if course.gpxpath == gpxURL {
                return IndexPath(item: index, section: 3) // recommendPlace 섹션
            }
        }
        return nil
    }

    @MainActor
    private func applySorting(sortType: String) {
        currentSortType = sortType

        switch sortType {
        case "가까운순":
            //가까운순 정렬: 사용자위치와 추천코스와의 거리가 짧은 순서대로 정렬
            courses = courses.sorted { course1, course2 in
                let distance1 = distanceViewModel.getCachedDistance(for: course1.gpxpath) ?? "0km"
                let distance2 = distanceViewModel.getCachedDistance(for: course2.gpxpath) ?? "0km"

                return distance1.localizedStandardCompare(distance2) == .orderedAscending
            }

        case "코스길이순":
            // 코스길이순: 짧은 거리부터 긴 거리 순으로 정렬
            courses = courses.sorted { course1, course2 in
                let distance1 = Int(course1.crsDstnc) ?? 0
                let distance2 = Int(course2.crsDstnc) ?? 0
                return distance1 < distance2
            }

        default:
            return
        }

        // UI 업데이트
        applyDataSnapshot()
    }

    //MARK: - 경고창
    // 권한이 거부되었을 때 설정 앱으로 안내하는 알림창 (한 번만)
    /// 앱 초기 실행 시 위치 권한을 요청하는 함수
    @MainActor
    private func requestInitialLocationPermission() async {
        let manager = LocationPermissionService.shared

        // 아직 권한을 요청한 적이 없을 때(.notDetermined)만 실행합니다.
        if manager.isPermissionNotDetermined() { // isPermissionNotDetermined()는 권한 상태가 .notDetermined인지 확인하는 가상 함수

            // 시스템 권한 팝업을 띄웁니다.
            let granted = await manager.requestLocationPermission()

            // 사용자가 권한을 허용하지 않았을 경우 경고창을 띄웁니다.
            if !granted {
                showPermissionDeniedAlert()
            }
        }
    }

    /// 권한이 거부되었을 때 보여줄 경고창
    private func showPermissionDeniedAlert() {
        showAlert(
            "위치 권한 필요",
            message: "추천 코스 기능을 사용하려면 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해 주세요.",
            onPrimaryAction: { _ in
                // "확인" 버튼 눌렀을 때 → 설정 앱으로 이동
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            },
            onCancelAction: { _ in

            }
        )
    }
}


extension PersonalViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) { }
}
