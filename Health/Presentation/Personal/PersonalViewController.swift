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
    private var courses: [WalkingCourse] = []
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
        config.interSectionSpacing = 15
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: config)
    }

    private func weekSummaryCellRegistration() -> UICollectionView.CellRegistration<WeekSummaryCell, Void> {
        UICollectionView.CellRegistration<WeekSummaryCell, Void>(cellNib: WeekSummaryCell.nib) { cell, indexPath, _ in
            // WeekSummaryCell 셀 설정
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
            // WalkingFilterCell 셀 설정
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

    private func loadWalkingCourses() {
        // networkService를 Task 외부에서 캡처
        let service = networkService

        Task {
            do {
                let response = try await service.request(
                    endpoint: .walkingCourses(pageNo: 1, numOfRows: 10),
                    as: WalkingCourseResponse.self
                )

                await MainActor.run {
                    self.courses = response.response.body.items.item
                    self.applyDataSnapshot()
                    print("✅ 로드된 코스 수: \(self.courses.count)")
                }
            } catch {
                print("❌ 코스 로드 실패: \(error)")
            }
        }
    }
}

extension PersonalViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) { }
}
