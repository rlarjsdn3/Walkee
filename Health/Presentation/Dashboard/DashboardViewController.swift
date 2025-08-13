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

        Task { try await viewModel.requestHKAutorizationIfNeeded() } // ⚠️ 테스트가 끝나면 반드시 해당 코드 삭제하기

        setupDataSource()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        let vSizeClass = traitCollection.verticalSizeClass
        let hSizeClass = traitCollection.horizontalSizeClass
        let env = DashboardViewModel.DashboardEnvironment(
            vericalClassIsRegular: vSizeClass == .regular,
            horizontalClassIsRegular: hSizeClass == .regular
        )
        
        viewModel.buildDashboardCells(for: env)
        viewModel.loadHKData() // TODO: - 적절한 다른 시점으로 메서드 옮겨보기 / 로드가 라이프-사이클 동안 한번만 실행되게 하기
        applySnapshot() // TODO: - 적절한 다른 시점으로 메서드 옮겨보기
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

        // -------
        var stackItems: [DashboardContent.Item] = []
        viewModel.goalRingIDs.forEach { id in
            stackItems.append(.goalRing(id))
        }
        // ------- 코드 리팩토링하기

        // -------
        viewModel.stackIDs.forEach { id in
            stackItems.append(.stackInfo(id))
        }
        snapshot.appendItems(stackItems, toSection: .ring)
        // ------- 코드 리팩토링하기
        
        // -------
        var chartsItem: [DashboardContent.Item] = []
        viewModel.chartsIDs.forEach { id in
            chartsItem.append(.barCharts(id))
        }
        snapshot.appendItems(chartsItem, toSection: .charts)
        // ------- 코드 리팩토링하기

        // ------
        var summaryItem: [DashboardContent.Item] = []
        viewModel.summaryIDs.forEach { id in
            summaryItem.append(.alanSummary(id))
        }
        snapshot.appendItems(summaryItem, toSection: .alan)
        // ------ 코드 리팩토링하기

        // ------
        var cardItems: [DashboardContent.Item] = []
        viewModel.cardIDs.forEach { id in
            cardItems.append(.cardInfo(id))
        }
        snapshot.appendItems(cardItems, toSection: .card)
        // ------- 코드 리팩토링하기

        // -------
        snapshot.appendItems([.text], toSection: .bottom)
        // ------- 코드 리팩토링하기
        
        dataSource?.apply(snapshot)
    }
}

fileprivate extension DashboardViewController {

    func createTopBarCellRegistration() -> UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void> {
        UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void>(cellNib: DashboardTopBarCollectionViewCell.nib) { cell, indexPath, _ in
            cell.update(with: .now) // TODO: - 실제 날짜 값으로 전달하기
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
            vm.didChange = { _ in self?.dashboardCollectionView.collectionViewLayout.invalidateLayout() }
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
        okAction.configuration.backgroundColor = .accent
        okAction.configuration.titleAttributes = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                  .foregroundColor: UIColor.systemBackground]
        alert.addAction(okAction)

        present(alert, animated: true)
    }
}
