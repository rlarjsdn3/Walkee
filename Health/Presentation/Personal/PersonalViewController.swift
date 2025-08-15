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

    private var dataSource: PersonalDiffableDataSource?
    private var courses: [WalkingCourse] = [] //실제 표시되는 코스 데이터
    private var allCourses: [WalkingCourse] = [] // 전체 코스 데이터
    private var easyLevelCourses: [WalkingCourse] = []    // "1" 난이도 코스들
    private var mediumLevelCourses: [WalkingCourse] = []  // "2" 난이도 코스들
    private var hardLevelCourses: [WalkingCourse] = []    // "3" 난이도 코스들
    private var llmRecommendedLevels: [String] = []  //	Alan에게 받아올 난이도(추후 작업 예정)
    private var currentSortType: String = "코스길이순" //기본 정렬
    private var networkService = DefaultNetworkService()
    private var didShowLocationPermissionAlert = false


    override func initVM() { }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        applyInitialSnapshot()
        loadWalkingCourses()
        Task {
            await requestInitialLocationPermission()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
        config.interSectionSpacing = 5
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
            // AISummaryCell 셀 설정
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
                guard let self = self else { return }

                Task {
                    // 👇 "가까운순" 필터를 선택했을 경우, 권한 확인 로직이 포함된 함수를 호출합니다.
                    if selectedFilter == "가까운순" {
                        await self.sortCoursesByDistanceWithPermissionCheck()
                    } else {
                        // 👇 그 외 다른 필터는 이전과 같이 바로 정렬 함수를 호출합니다.
                        await MainActor.run {
                            self.applySorting(sortType: selectedFilter)
                        }
                    }
                }
            }
        }
    }

    private func createRecommendPlaceCellRegistration() -> UICollectionView.CellRegistration<RecommendPlaceCell, WalkingCourse> {
        UICollectionView.CellRegistration<RecommendPlaceCell, WalkingCourse>(cellNib: RecommendPlaceCell.nib) { cell, indexPath, course in
            cell.configure(with: course)
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
                print("중복 코스 스킵: \(course.crsKorNm)")
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
                print("알 수 없는 난이도: \(course.crsLevel) - \(course.crsKorNm)")
            }
        }

        // 각 배열을 랜덤하게 섞기
        easyLevelCourses.shuffle()
        mediumLevelCourses.shuffle()
        hardLevelCourses.shuffle()

        // 결과 출력
        print("난이도별 분류 완료:")
        print("- 하(1): \(easyLevelCourses.count)개")
        print("- 중(2): \(mediumLevelCourses.count)개")
        print("- 상(3): \(hardLevelCourses.count)개")
        print("- 총 코스: \(easyLevelCourses.count + mediumLevelCourses.count + hardLevelCourses.count)개")
    }

    @MainActor
    private func loadWalkingCourses() {
        Task {
            allCourses = WalkingCourseService.shared.loadWalkingCourses()
            separateCoursesByDifficulty()

            // 랜덤하게 5개 선택
            if easyLevelCourses.count > 5 {
                courses = Array(easyLevelCourses.prefix(5)) // 하 난이도에서 5개만
            } else {
                courses = easyLevelCourses // 하 난이도 전체 (5개 미만일 경우)
            }

            // 기본적으로 코스 길이순으로 필터링 되어서 보여줌
            applySorting(sortType: self.currentSortType)
            print("코스 수: \(courses.count)")
        }
    }

    @MainActor
    private func applySorting(sortType: String) {
        currentSortType = sortType

        switch sortType {
        case "가까운순":
            // 가까운순: 일단 플레이스홀더 (나중에 위치 기반 정렬 구현)
            print("가까운순으로 정렬 (미구현)")

        case "코스길이순":
            // 코스길이순: 짧은 거리부터 긴 거리 순으로 정렬
            courses = courses.sorted { course1, course2 in
                let distance1 = Int(course1.crsDstnc) ?? 0
                let distance2 = Int(course2.crsDstnc) ?? 0
                return distance1 < distance2
            }
            print("코스길이순으로 정렬 완료")

            // 정렬 결과 확인 (디버깅용)
            print("정렬된 코스들:")
            for (index, course) in courses.enumerated() {
                print("  \(index + 1). \(course.crsKorNm): \(course.crsDstnc)km")
            }

        default:
            print("알 수 없는 정렬 타입: \(sortType)")
        }

        // UI 업데이트
        applyDataSnapshot()
    }

    // 권한이 거부되었을 때 설정 앱으로 안내하는 알림창 (한 번만)
    /// 앱 초기 실행 시 위치 권한을 요청하는 함수
    @MainActor
    private func requestInitialLocationPermission() async {
        let manager = LocationPermissionService.shared

        // 아직 권한을 요청한 적이 없을 때(.notDetermined)만 실행합니다.
        if manager.isPermissionNotDetermined() { // isPermissionNotDetermined()는 권한 상태가 .notDetermined인지 확인하는 가상 함수
            print("최초 권한을 요청합니다.")

            // 시스템 권한 팝업을 띄웁니다.
            let granted = await manager.requestLocationPermission()

            // 사용자가 권한을 허용하지 않았을 경우 경고창을 띄웁니다.
            if !granted {
                print("사용자가 권한을 거부했습니다. 경고창을 표시합니다.")
                showPermissionDeniedAlert()
            }
        } else {
            print("이미 권한이 설정되어 있습니다 (허용 또는 거부됨).")
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
                print("위치 권한 설정 취소됨")
            }
        )
    }

    @MainActor
    private func sortCoursesByDistanceWithPermissionCheck() async {
        let manager = LocationPermissionService.shared

        // 현재 권한 상태를 다시 확인
        if manager.checkCurrentPermissionStatus() {
            // 1. 권한이 이미 허용된 상태일 경우
            print("위치 권한 있음. 가까운순 정렬을 실행합니다.")

            // TODO: - 실제 사용자 위치를 가져오는 로직 구현 필요
            // let userLocation = await LocationService.shared.getCurrentLocation()

            // 위치 정보를 가져온 후, 정렬 적용
            self.applySorting(sortType: "가까운순")

        } else {
            // 권한이 거부된 상태일 경우 (.denied)
            guard !didShowLocationPermissionAlert else {
                return
            }
            self.showPermissionDeniedAlert()
            // 알림창을 보여준 후, 플래그를 true로 변경
            self.didShowLocationPermissionAlert = true
        }
    }
}


extension PersonalViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) { }
}
