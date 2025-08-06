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
    override func initVM() {

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDataSource()
        applySnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func setupAttribute() {
        super.setupAttribute()

        applyBackgroundGradient(.midnightBlack)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.setCollectionViewLayout(
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
        config.interSectionSpacing = 10
        return UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider,
            configuration: config
        )
    }

    private func setupDataSource() {
        let segmentCellRegistration = createSegmentCellRegistration()
        let chartCellRegistration = createChartCellRegistration()

        dataSource = PersonalDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            item.dequeueReusableCollectionViewCell(
                collectionView: collectionView,
                segmentCellRegistration: segmentCellRegistration,
                chartCellRegistration: chartCellRegistration,
                indexPath: indexPath
            )
        }
    }

    private func createSegmentCellRegistration() -> UICollectionView.CellRegistration<SegmentControlCell, Void> {
        UICollectionView.CellRegistration<SegmentControlCell, Void>(cellNib: SegmentControlCell.nib) { cell, indexPath, _ in
            // 셀 설정은 셀 자체에서 처리
        }
    }

    private func createChartCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewCell, Void> {
        UICollectionView.CellRegistration<UICollectionViewCell, Void>(cellNib: ChartCollectionViewCell.nib) { cell, indexPath, _ in
            guard cell is ChartCollectionViewCell else { return }
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<PersonalContent.Section, PersonalContent.Item>()
        snapshot.appendSections([.segment, .chart])
        snapshot.appendItems([.segmentControl], toSection: .segment)
        snapshot.appendItems([.chartData], toSection: .chart)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

extension PersonalViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didHighlightItemAt indexPath: IndexPath
    ) {
    }
}
