//
//  HomeViewController.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

final class DashboardViewController: CoreGradientViewController {

    typealias DashboardDiffableDataSource = UICollectionViewDiffableDataSource<DashboardContent.Section, DashboardContent.Item>

    @IBOutlet weak var dashboardCollectionView: UICollectionView!

    private var dataSource: DashboardDiffableDataSource?

    private lazy var viewModel: DashboardViewModel = {
        .init()
    }()

    convenience init(date: Date, coder: NSCoder) {
        self.init(coder: coder)!
        // TODO: - CalendarVC에서 날짜를 넘겨주기 위한 생성자 구성하기
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDataSource()
        applySnapshot()
    }

    override func setupAttribute() {
        dashboardCollectionView.delegate = self
        dashboardCollectionView.backgroundColor = .clear
        dashboardCollectionView.setCollectionViewLayout(
            createCollectionViewLayout(),
            animated: false
        )
        dashboardCollectionView.contentInset = UIEdgeInsets(
            top: 54, left: .zero, // TODO: - 네비게이션 바에 맞게 인셋 값 조정하기
            bottom: 32, right: .zero
        )
        dashboardCollectionView.scrollIndicatorInsets =  UIEdgeInsets(
            top: 46, left: .zero,
            bottom: 24, right: .zero
        )

        applyBackgroundGradient(.midnightBlack)
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
        let textCellRegistration = createTextCellRegistration()
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
                textCellRegistration: textCellRegistration,
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

    private func applySnapshot() {
        // TODO: - 스냅샷 다시 구성하기

        var snapshot = NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>()
        snapshot.appendSections([.top, .ring, .charts, .alan, .card, .bottom])
        snapshot.appendItems([.topBar], toSection: .top)
        snapshot.appendItems([.goalRing(.init()), .stackInfo(.init()), .stackInfo(.init()), .stackInfo(.init())], toSection: .ring)
        snapshot.appendItems([.barCharts(.init())], toSection: .charts)
        snapshot.appendItems([.alanSummary(.init())], toSection: .alan)
        snapshot.appendItems([.cardInfo(.init()),  .cardInfo(.init()), .cardInfo(.init()), .cardInfo(.init())], toSection: .card)
        snapshot.appendItems([.text], toSection: .bottom)
        dataSource?.apply(snapshot)
    }
}

fileprivate extension DashboardViewController {

    func createTopBarCellRegistration() -> UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void>(cellNib: DashboardTopBarCollectionViewCell.nib) { cell, indexPath, _ in
        }
    }

    func createDailyGoalRingCellRegistration() -> UICollectionView.CellRegistration<DailyGoalRingCollectionViewCell, DailyGoalRingCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<DailyGoalRingCollectionViewCell, DailyGoalRingCellViewModel>(cellNib: DailyGoalRingCollectionViewCell.nib) { cell, indexPath, viewModel in
            cell.configure(with: viewModel)
        }
    }

    func createHealthInfoStackCellRegistration() -> UICollectionView.CellRegistration<HealthInfoStackCollectionViewCell, HealthInfoStackCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<HealthInfoStackCollectionViewCell, HealthInfoStackCellViewModel>(cellNib: HealthInfoStackCollectionViewCell.nib) { cell, indexPath, viewModel in
            cell.configure(with: viewModel, parent: self)
        }
    }

    func createBarChartsCellRegistration() -> UICollectionView.CellRegistration<DashboardBarChartsCollectionViewCell, DashboardBarChartsCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<DashboardBarChartsCollectionViewCell, DashboardBarChartsCellViewModel>(cellNib: DashboardBarChartsCollectionViewCell.nib) { cell, indexPath, viewModel in
        }
    }

    func createAlanSummaryCellRegistration() -> UICollectionView.CellRegistration<AlanActivitySummaryCollectionViewCell, AlanActivitySummaryCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<AlanActivitySummaryCollectionViewCell, AlanActivitySummaryCellViewModel>(cellNib: AlanActivitySummaryCollectionViewCell.nib) { cell, indexPath, viewModel in
            cell.didReceiveSummaryMessage = { [weak self] _ in self?.dashboardCollectionView.collectionViewLayout.invalidateLayout() }
            cell.configure(with: viewModel)
        }
    }

    func createHealthInfoCardCellRegistration() -> UICollectionView.CellRegistration<HealthInfoCardCollectionViewCell, HealthInfoCardCellViewModel> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<HealthInfoCardCollectionViewCell, HealthInfoCardCellViewModel>(cellNib: HealthInfoCardCollectionViewCell.nib) { cell, indexPath, viewModel in
            cell.configure(with: viewModel) // TODO: - 실제 CoreData에서 가져오기
        }
    }

    func createTextCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Void> {
        // TODO: - 셀 콘텐츠 구성하기
        UICollectionView.CellRegistration<UICollectionViewListCell, Void> { cell, indexPath, viewModel in
            var config = cell.defaultContentConfiguration()
            config.text = "Alan AI는 정보 제공시 실수를 할 수 있으니 다시 한번 확인하세요."
            config.textProperties.font = .preferredFont(forTextStyle: .footnote)
            config.textProperties.color = .secondaryLabel
            config.textProperties.alignment = .center
            cell.contentConfiguration = config
            cell.backgroundConfiguration?.backgroundColor = .clear
        }
    }

    func createBasicSupplementaryViewRegistration() -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell> {
        // TODO: - 헤더 콘텐츠 구성하기
        UICollectionView.SupplementaryRegistration(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, kind, indexPath in
            guard let section = self?.dataSource?.sectionIdentifier(for: indexPath.section)
            else { return }

            var reusableSupplementaryView = supplementaryView
            let infoDetailBtn = InfoDetailButton(touchHandler: { _ in print("Info Detail Button Tapped") }) // TODO: - DetailButton 리팩토링, 플로팅 시트 띄우기
            section.setContentConfiguration(
                basicSupplementaryView: &reusableSupplementaryView,
                detailButton: infoDetailBtn
            )
        }
    }
}

extension DashboardViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didHighlightItemAt indexPath: IndexPath
    ) {
    }
}
