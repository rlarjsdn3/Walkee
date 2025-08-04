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

        dataSource = DashboardDiffableDataSource(collectionView: dashboardCollectionView) { collectionView, indexPath, item in
            item.dequeueReusableCollectionViewCell(
                collectionView: collectionView,
                topBarCellRegistration: topBarCellRegistration,
                indexPath: indexPath
            )
        }

        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            return nil
        }
    }

    private func createTopBarCellRegistration() -> UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void> {
        UICollectionView.CellRegistration<DashboardTopBarCollectionViewCell, Void>(cellNib: DashboardTopBarCollectionViewCell.nib) { cell, indexPath, _ in
        }
    }


    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<DashboardContent.Section, DashboardContent.Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.topBar], toSection: .main)
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
