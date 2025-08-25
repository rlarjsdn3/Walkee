//
//  HomeViewController.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

import TSAlertController

final class DashboardViewController: HealthNavigationController, Alertable, ScrollableToTop {

    typealias DashboardDiffableDataSource = UICollectionViewDiffableDataSource<DashboardContent.Section, DashboardContent.Item>

    @IBOutlet weak var dashboardCollectionView: UICollectionView!
    private let refreshControl = UIRefreshControl()

    private var dataSource: DashboardDiffableDataSource?
    
    //
    private var hasBuiltLayout = false
    private var hasLoadedData = false
    
    lazy var viewModel: DashboardViewModel = {
        .init()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
        registerNotification()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        buildLayout()
        setupDataSource()
        applySnapshot()
		// 위젯 스냅샷 update
		viewModel.updateWidgetSnapshot()
    }

    func scrollToTop() {
        guard isViewLoaded, dashboardCollectionView != nil else { return }
        dashboardCollectionView.setContentOffset(.zero, animated: true)
    }

    private func buildLayout() {
        guard !hasBuiltLayout else { return }

        let vSizeClass = traitCollection.verticalSizeClass
        let hSizeClass = traitCollection.horizontalSizeClass
        let env = DashboardViewModel.DashboardEnvironment(
            vericalClassIsRegular: vSizeClass == .regular,
            horizontalClassIsRegular: hSizeClass == .regular
        )
        viewModel.buildDashboardCells(for: env)
        hasBuiltLayout = true
    }

    private func loadData() {
        guard !hasLoadedData else { return }

        viewModel.loadHKData()
        hasLoadedData = true
    }

    override func setupAttribute() {
        applyBackgroundGradient(.midnightBlack)

        healthNavigationBar.title = "대시보드"
        healthNavigationBar.titleImage = UIImage(systemName: "chart.xyaxis.line")
        healthNavigationBar.trailingBarButtonItems = [
            HealthBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                primaryAction: shareActivityRingImage
            )
        ]

        refreshControl.addTarget(
            self,
            action: #selector(refreshHKData),
            for: .valueChanged
        )

        dashboardCollectionView.backgroundColor = .clear
        dashboardCollectionView.setCollectionViewLayout(
            createCollectionViewLayout(),
            animated: false
        )
        dashboardCollectionView.contentInset = UIEdgeInsets(
            top: 12, left: .zero,
            bottom: 32, right: .zero
        )
        dashboardCollectionView.scrollIndicatorInsets =  UIEdgeInsets(
            top: 20, left: .zero,
            bottom: 24, right: .zero
        )
        dashboardCollectionView.refreshControl = refreshControl
    }

    private func registerNotification() {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshHKData),
            name: .didUpdateGoalStepCount,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshHKData),
            name: .didChangeHKSharingAuthorizationStatus,
            object: nil
        )
    }

    private func shareActivityRingImage() {
        viewModel.loadHKData(includeAIResponse: false)
        Task.delay(for: 0.2) { @MainActor in await presentActivityRingShareSheet() }
    }

    @objc private func refreshHKData() {
        viewModel.loadHKData()
		// 당겨서 새로고침 때에도 갱신
		viewModel.updateWidgetSnapshot()
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
                    self?.dataSource?.apply(snapshot, animatingDifferences: false)
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
            cell.bind(with: vm)
        }
    }

    func createTextCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Void> {
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
        UICollectionView.SupplementaryRegistration(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, kind, indexPath in
            guard let section = self?.dataSource?.sectionIdentifier(for: indexPath.section)
            else { return }

            var reusableSupplementaryView = supplementaryView
            let infoDetailBtn = InfoDetailButton(touchHandler: { [weak self] _ in self?.showWalkingBalanceGuideSheet() })
            section.setContentConfiguration(
                basicSupplementaryView: &reusableSupplementaryView,
                detailButton: infoDetailBtn
            )
        }
    }
}

fileprivate extension DashboardViewController {

    func presentActivityRingShareSheet() async {
        let stepCountReadPermissionGranted = await viewModel.checkHKHasAnyReadPermission(typeIdentifier: .stepCount)

        if stepCountReadPermissionGranted {
            let image = snapshotFirstTwoSections(in: dashboardCollectionView)
            let itemSource = DashboardActivityItemSrouce(title: "안녕", image: image)
            let avc = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)

            if let pop = avc.popoverPresentationController {
                pop.sourceView = view
                pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }
            present(avc, animated: true)
        } else {
            showAlert(
                "권한 설정 필요",
                message: """
                         대시보드 현황을 공유하려면 걸음 수 건강 데이터 접근 권한이 필요합니다.
                         
                         경로: 프로필(우측 상단) ⏵ 개인정보 보호 ⏵ 앱 ⏵ Health  
                         위 경로에서 앱의 데이터 접근 권한을 해제하거나 다시 활성화할 수 있습니다.
                         """,
                primaryTitle: "설정으로 이동",
                onPrimaryAction: ({ [weak self] _ in
                    self?.openURL(string: "x-apple-health://")
                }),
                onCancelAction: ({ _ in })
            )
        }
    }

    func sectionRect(in collectionView: UICollectionView, section: Int) -> CGRect {
        collectionView.layoutIfNeeded()
        let layout = collectionView.collectionViewLayout

        var union = CGRect.null
        let itemCount = collectionView.numberOfItems(inSection: section)

        for item in 0..<itemCount {
            let indexPath = IndexPath(item: item, section: section)
            if let attr = layout.layoutAttributesForItem(at: indexPath) {
                union = union.union(attr.frame)
            }
        }
        return union
    }

    func snapshot(of rect: CGRect, in collectionView: UICollectionView, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        collectionView.layoutIfNeeded()

        let renderFormat = UIGraphicsImageRendererFormat.default()
        renderFormat.scale = scale
        // 출력 이미지의 좌표 원점은 (0,0)이며, 크기는 rect.size입니다.
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: renderFormat)

        let originalOffset = collectionView.contentOffset
        defer {
            collectionView.backgroundColor = .clear
            collectionView.setContentOffset(originalOffset, animated: false)
            collectionView.layoutIfNeeded()
        }

        let image = renderer.image { context in
            // 지정한 rect를 (0,0)부터 시작하도록 맞추기 위해
            // 원점을 rect.origin만큼 반대로 평행 이동합니다.
            context.cgContext.translateBy(x: -rect.origin.x, y: -rect.origin.y)

            let topColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "292A3D").withAlphaComponent(0.9)
                : UIColor.systemBackground
            }.cgColor
            let bottomColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "000000").withAlphaComponent(0.9)
                : UIColor.systemBackground
            }.cgColor

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [topColor, bottomColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                // 상단에 흰색 라인이 보이지 않도록, 시작점을 약간 위로 올려서 그라디언트를 그립니다.
                let start = CGPoint(x: 0, y: -20)
                let end   = CGPoint(x: 0, y: rect.size.height)
                context.cgContext.drawLinearGradient(gradient, start: start, end: end, options: [])
            }

            let viewportHeight = collectionView.bounds.height

            var tileMinY = rect.minY
            while tileMinY < rect.maxY {
                let tileHeight = min(viewportHeight, rect.maxY - tileMinY)
                let targetOffset = CGPoint(x: rect.minX, y: tileMinY)
                collectionView.setContentOffset(CGPoint(x: 0, y: targetOffset.y), animated: false)
                collectionView.layoutIfNeeded()

                collectionView.backgroundColor = .clear
                collectionView.layer.render(in: context.cgContext)

                tileMinY += tileHeight
            }
        }

        return image
    }

    func snapshotFirstTwoSections(
        in collectionView: UICollectionView,
        extraInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    ) -> UIImage {
        let s0 = sectionRect(in: collectionView, section: 0)
        let s1 = sectionRect(in: collectionView, section: 1)
        var union = s0.union(s1)
        
        union.origin.x -= extraInsets.left
        union.origin.y -= extraInsets.top
        union.size.width  += (extraInsets.left + extraInsets.right)
        union.size.height += (extraInsets.top  + extraInsets.bottom)

        return snapshot(of: union, in: collectionView)
    }
}

fileprivate extension DashboardViewController {

    func showWalkingBalanceGuideSheet() {
        let sections = [
            GuideSection(
                title: "보행 속도",
                description: WalkingBalanceAnaysisString.walkingSpeed
            ),
            GuideSection(
                title: "보행 보폭",
                description: WalkingBalanceAnaysisString.stepLength
            ),
            GuideSection(
                title: "보행 비대칭성",
                description: WalkingBalanceAnaysisString.walkingAsymmetryPercentage
            ),
            GuideSection(
                title: "이중 지지 시간",
                description: WalkingBalanceAnaysisString.doubleSupportPercentage
            ),
        ]
        let guideView = GuideView.create(with: sections)

        showFloatingSheet(guideView) { _ in }
    }
}
