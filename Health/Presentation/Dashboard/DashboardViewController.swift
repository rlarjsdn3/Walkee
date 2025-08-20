//
//  HomeViewController.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import HealthKit
import UIKit

import TSAlertController

final class DashboardViewController: CoreGradientViewController {

    typealias DashboardDiffableDataSource = UICollectionViewDiffableDataSource<DashboardContent.Section, DashboardContent.Item>

    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var dashboardCollectionView: UICollectionView!

    private var dataSource: DashboardDiffableDataSource?
    
    //
    private var hasBuiltLayout = false
    private var hasLoadedData = false
    
    lazy var viewModel: DashboardViewModel = {
        .init()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        // TODO: - 다른 메서드로 빼서 코드 정돈하기
        if !hasBuiltLayout {
            let vSizeClass = traitCollection.verticalSizeClass
            let hSizeClass = traitCollection.horizontalSizeClass
            let env = DashboardViewModel.DashboardEnvironment(
                vericalClassIsRegular: vSizeClass == .regular,
                horizontalClassIsRegular: hSizeClass == .regular
            )
            viewModel.buildDashboardCells(for: env)
            hasBuiltLayout = true
        }
        
        if !hasLoadedData {
            viewModel.loadHKData()
            setupDataSource()
            applySnapshot()
            hasLoadedData = true
        }
    }

    override func setupAttribute() {
        refreshControl.addTarget(
            self,
            action: #selector(refreshHKData),
            for: .valueChanged
        )

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
        dashboardCollectionView.refreshControl = refreshControl

        applyBackgroundGradient(.midnightBlack)
    }

    @objc private func refreshHKData() {
        viewModel.loadHKData(includeAISummary: true)
        Task.delay(for: 1.0) { @MainActor in refreshControl.endRefreshing() }
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
        var snapshot = NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>()
        appendTopBarSection(to: &snapshot)
        appendGoalRingSection(to: &snapshot)
        appendBarChartsSection(to: &snapshot)
        appendAISummarySection(to: &snapshot)
        appendCardSection(to: &snapshot)
        appendBottomBarSection(to: &snapshot)
        dataSource?.apply(snapshot)
    }
}

fileprivate extension DashboardViewController {

    private func appendTopBarSection(to snapshot: inout NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>) {
        snapshot.appendSections([.top])

        var items: [DashboardContent.Item] = []
        viewModel.topIDs.forEach { id in
            items.append(.topBar(id))
        }
        snapshot.appendItems(items, toSection: .top)
    }

    private func appendGoalRingSection(to snapshot: inout NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>) {
        snapshot.appendSections([.ring])

        var items: [DashboardContent.Item] = []
        viewModel.goalRingIDs.forEach { id in
            items.append(.goalRing(id))
        }
        viewModel.stackIDs.forEach { id in
            items.append(.stackInfo(id))
        }
        snapshot.appendItems(items, toSection: .ring)
    }

    private func appendBarChartsSection(to snapshot: inout NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>) {
        // 기준 날짜가 `오늘`이 아니라면 섹션 추가하지 않기
        guard viewModel.anchorDate.isEqual(with: .now) else { return }

        snapshot.appendSections([.charts])

        var item: [DashboardContent.Item] = []
        viewModel.chartsIDs.forEach { id in
            item.append(.barCharts(id))
        }
        snapshot.appendItems(item, toSection: .charts)
    }

    private func appendAISummarySection(to snapshot: inout NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>) {
        // 기준 날짜가 `오늘`이 아니라면 섹션 추가하지 않기
        guard viewModel.anchorDate.isEqual(with: .now) else { return }

        snapshot.appendSections([.alan])

        var item: [DashboardContent.Item] = []
        viewModel.summaryIDs.forEach { id in
            item.append(.alanSummary(id))
        }
        snapshot.appendItems(item, toSection: .alan)
    }

    private func appendCardSection(to snapshot: inout NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>) {
        snapshot.appendSections([.card])

        var items: [DashboardContent.Item] = []
        viewModel.cardIDs.forEach { id in
            items.append(.cardInfo(id))
        }
        snapshot.appendItems(items, toSection: .card)
    }

    private func appendBottomBarSection(to snapshot: inout NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>) {
        snapshot.appendSections([.bottom])
        snapshot.appendItems([.text], toSection: .bottom)
    }
}

fileprivate extension DashboardViewController {

    func createTopBarCellRegistration() -> UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, DashboardTopBarViewModel.ItemID> {
        UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, DashboardTopBarViewModel.ItemID>(cellNib: DashboardTopBarCollectionViewCell.nib) { [weak self] cell, indexPath, id in
            guard let vm = self?.viewModel.topCells[id] else { return }
            cell.bind(with: vm)
        }
    }

    func createDailyGoalRingCellRegistration() -> UICollectionView.CellRegistration<DailyGoalRingCollectionViewCell, DailyGoalRingCellViewModel.ItemID> {
        UICollectionView.CellRegistration<DailyGoalRingCollectionViewCell, DailyGoalRingCellViewModel.ItemID>(cellNib: DailyGoalRingCollectionViewCell.nib) { [weak self] cell, indexPath, id in
            guard let vm = self?.viewModel.goalRingCells[id] else { return }
            cell.bind(with: vm)
        }
    }

    func createHealthInfoStackCellRegistration() -> UICollectionView.CellRegistration<HealthInfoStackCollectionViewCell, HealthInfoStackCellViewModel.ItemID> {
        UICollectionView.CellRegistration<HealthInfoStackCollectionViewCell, HealthInfoStackCellViewModel.ItemID>(cellNib: HealthInfoStackCollectionViewCell.nib) { [weak self] cell, indexPath, id in
            guard let vm = self?.viewModel.stackCells[id] else { return }
            cell.bind(with: vm, parent: self)
        }
    }

    func createBarChartsCellRegistration() -> UICollectionView.CellRegistration<DashboardBarChartsCollectionViewCell, DashboardBarChartsCellViewModel.ItemID> {
        UICollectionView.CellRegistration<DashboardBarChartsCollectionViewCell, DashboardBarChartsCellViewModel.ItemID>(cellNib: DashboardBarChartsCollectionViewCell.nib) { [weak self] cell, indexPath, id in
            guard let vm = self?.viewModel.chartsCells[id] else { return }
            cell.bind(with: vm)
        }
    }

    func createAlanSummaryCellRegistration() -> UICollectionView.CellRegistration<AlanActivitySummaryCollectionViewCell, AlanActivitySummaryCellViewModel.ItemID> {
        UICollectionView.CellRegistration<AlanActivitySummaryCollectionViewCell, AlanActivitySummaryCellViewModel.ItemID>(cellNib: AlanActivitySummaryCollectionViewCell.nib) { [weak self] cell, indexPath, id in
            guard let vm = self?.viewModel.summaryCells[id] else { return }
            vm.didChange = { _ in
                guard var snapshot = self?.dataSource?.snapshot() else { return }

                snapshot.reconfigureItems([.alanSummary(id)])
                self?.dashboardCollectionView.performBatchUpdates {
                    self?.dataSource?.apply(snapshot, animatingDifferences: true)
                } completion: { _ in
                    self?.dashboardCollectionView.collectionViewLayout.invalidateLayout()
                }
            }
            cell.bind(with: vm)
        }
    }

    func createHealthInfoCardCellRegistration() -> UICollectionView.CellRegistration<HealthInfoCardCollectionViewCell, HealthInfoCardCellViewModel.ItemID> {
        UICollectionView.CellRegistration<HealthInfoCardCollectionViewCell, HealthInfoCardCellViewModel.ItemID>(cellNib: HealthInfoCardCollectionViewCell.nib) { [weak self] cell, indexPath, id in
            guard let vm = self?.viewModel.cardCells[id] else { return }
            cell.bind(with: vm) // TODO: - 실제 CoreData에서 가져오기
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
            let infoDetailBtn = InfoDetailButton(touchHandler: { [weak self] _ in self?.showWalkingBalanceAnaysisDescriptionsAlert() })
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

fileprivate extension DashboardViewController {

    func showWalkingBalanceAnaysisDescriptionsAlert() {
        let descsView = HeaderDescriptionsView()
        descsView.descriptions = [
            WalkingBalanceAnaysisString.stepLength,
            WalkingBalanceAnaysisString.walkingSpeed,
            WalkingBalanceAnaysisString.walkingAsymmetryPercentage,
            WalkingBalanceAnaysisString.doubleSupportPercentage
        ]

        let alert = TSAlertController(
            descsView,
            options: [.dismissOnSwipeDown, .interactiveScaleAndDrag],
            preferredStyle: .floatingSheet
        )

        if traitCollection.verticalSizeClass == .regular
            && traitCollection.horizontalSizeClass == .regular {
            alert.preferredStyle = .alert
            alert.viewConfiguration.size.width = .proportional(minimumRatio: 0.66, maximumRatio: 0.66)
        }

        let okAction = TSAlertAction(title: "확인")
        okAction.highlightType = .fadeIn
        okAction.configuration.backgroundColor = .accent
        okAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                  .foregroundColor: UIColor.systemBackground]
        alert.addAction(okAction)

        present(alert, animated: true)
    }
}
