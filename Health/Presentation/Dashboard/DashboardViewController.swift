//
//  HomeViewController.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

final class DashboardViewController: CoreViewController {

    typealias DashboardDiffableDataSource = UICollectionViewDiffableDataSource<DashboardContent.Section, DashboardContent.Item>

    @IBOutlet weak var dashboardCollectionView: UICollectionView!

    private var dataSource: DashboardDiffableDataSource?

    private lazy var viewModel: DashboardViewModel = {
        .init()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDataSource()
        applySnapshot()
    }

    override func setupAttribute() {
        dashboardCollectionView.delegate = self
        dashboardCollectionView.setCollectionViewLayout(
            createCollectionViewLayout(),
            animated: false
        )
    }

    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { [weak self] sectionIndex, environment in
            guard let section = self?.dataSource?.sectionIdentifier(for: sectionIndex)
            else { return nil }

            return section.buildLayout(environment)
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 16
        return UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider,
            configuration: config
        )
    }

    private func setupDataSource() {
        let topBarCellRegistration = createTopBarCellRegistration()
        let dailyGoalRingCellRegistration = createDailyGoalRingCellRegistration()
        let healthInfoStackCellRegistration = createHealthInfoStackCellRegistration()
        let barChartsCellRegistration = createBarChartsCellRegistration()
        let alanSummaryCellRegistration = createAlanSummaryCellRegistration()
        let healthInfoCardCellRegistration = createHealthInfoCardCellRegistration()
        let basicSupplementaryViewRegistration = createBasicSupplementaryViewRegistration()

        dataSource = DashboardDiffableDataSource(collectionView: dashboardCollectionView) { collectionView, indexPath, item in
            item.dequeueReusableCollectionViewCell(
                collectionView: collectionView,
                topBarCellRegistration: topBarCellRegistration,
                dailyGoalRingCellRegistration: dailyGoalRingCellRegistration,
                healthInfoStackCellRegistration: healthInfoStackCellRegistration,
                barChartsCellRegistration: barChartsCellRegistration,
                alanSummaryCellRegistration: alanSummaryCellRegistration,
                healthInfoCardCellRegistration: healthInfoCardCellRegistration,
                indexPath: indexPath
            )
        }

        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let section = self?.dataSource?.sectionIdentifier(for: indexPath.section)
            else { return nil }
            return section.dequeueReusableSupplementaryView(
                collectionView: collectionView,
                basicSupplementaryViewRegistration: basicSupplementaryViewRegistration,
                indexPath: indexPath
            )
        }
    }

    private func createTopBarCellRegistration() -> UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void>(cellNib: DashboardTopBarCollectionViewCell.nib) { cell, indexPath, _ in
        }
    }

    private func createDailyGoalRingCellRegistration() -> UICollectionView.CellRegistration<DailyGoalRingCollectionViewCell, DailyGoalRingCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<DailyGoalRingCollectionViewCell, DailyGoalRingCellViewModel>(cellNib: DailyGoalRingCollectionViewCell.nib) { cell, indexPath, viewModel in
        }
    }

    private func createHealthInfoStackCellRegistration() -> UICollectionView.CellRegistration<HealthInfoStackCollectionViewCell, HealthInfoStackCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<HealthInfoStackCollectionViewCell, HealthInfoStackCellViewModel>(cellNib: HealthInfoStackCollectionViewCell.nib) { cell, indexPath, viewModel in
        }
    }

    private func createBarChartsCellRegistration() -> UICollectionView.CellRegistration<DashboardBarChartsCollectionViewCell, DashboardBarChartsCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<DashboardBarChartsCollectionViewCell, DashboardBarChartsCellViewModel>(cellNib: DashboardBarChartsCollectionViewCell.nib) { cell, indexPath, viewModel in
        }
    }

    private func createAlanSummaryCellRegistration() -> UICollectionView.CellRegistration<AlanActivitySummaryCollectionViewCell, AlanActivitySummaryCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<AlanActivitySummaryCollectionViewCell, AlanActivitySummaryCellViewModel>(cellNib: AlanActivitySummaryCollectionViewCell.nib) { cell, indexPath, viewModel in
        }
    }

    private func createHealthInfoCardCellRegistration() -> UICollectionView.CellRegistration<HealthInfoCardCollectionViewCell, HealthInfoCardCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<HealthInfoCardCollectionViewCell, HealthInfoCardCellViewModel>(cellNib: HealthInfoCardCollectionViewCell.nib) { cell, indexPath, viewModel in
        }
    }

    private func createBasicSupplementaryViewRegistration() -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell> {
        // TODO: - 헤더 콘텐츠 구성하기
        UICollectionView.SupplementaryRegistration(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, kind, indexPath in
            var config = supplementaryView.defaultContentConfiguration()
            config.text = "Supplementary View"
            supplementaryView.contentConfiguration = config
        }
    }

    private func applySnapshot() {
        // TODO: - 스냅샷 다시 구성하기

        var snapshot = NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>()
        snapshot.appendSections([.top, .ring, .charts, .alan, .stack])
        snapshot.appendItems([.topBar], toSection: .top)
        snapshot.appendItems([.goalRing(.init()), .stackInfo(.init()), .stackInfo(.init()), .stackInfo(.init())], toSection: .ring)
        snapshot.appendItems([.barCharts(.init())], toSection: .charts)
        snapshot.appendItems([.alanSummary(.init())], toSection: .alan)
        snapshot.appendItems([.cardInfo(.init()),  .cardInfo(.init()), .cardInfo(.init()), .cardInfo(.init())], toSection: .stack)

        dataSource?.apply(snapshot)
    }
}

extension DashboardViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didHighlightItemAt indexPath: IndexPath
    ) {
    }
}
