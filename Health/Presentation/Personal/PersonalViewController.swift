//
//  PersonalViewController.swift
//  Health
//
//  Created by Seohyun Kim on 8/1/25.
//
import UIKit

class PersonalViewController: CoreGradientViewController {

    typealias PersonalDiffableDataSource = UICollectionViewDiffableDataSource<PersonalContent.Section, PersonalContent.Item>

    @IBOutlet weak var collectionView: UICollectionView!

    private var dataSource: PersonalDiffableDataSource?
    private var courses: [WalkingCourse] = [] //실제 표시되는 코스 데이터
    private var allCourses: [WalkingCourse] = [] // 전체 코스 데이터
    private var easyLevelCourses: [WalkingCourse] = []    // "1" 난이도 코스들
    private var mediumLevelCourses: [WalkingCourse] = []  // "2" 난이도 코스들
    private var hardLevelCourses: [WalkingCourse] = []    // "3" 난이도 코스들
    private var llmRecommendedLevels: [String] = []  //	Alan에게 받아올 난이도(추후 작업 예정)
    private var currentSortType: String = "가까운순" //기본 정렬
    private var networkService = DefaultNetworkService()

    override func initVM() { }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        applyInitialSnapshot()
        loadWalkingCourses()
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

                // 메인 스레드에서 정렬 실행
                Task {
                    await MainActor.run {
                        self?.applySorting(sortType: selectedFilter)
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

            // UI 업데이트
            applyDataSnapshot()
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
}

extension PersonalViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) { }
}
