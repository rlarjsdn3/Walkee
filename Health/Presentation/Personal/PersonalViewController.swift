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

    override func initVM() { }

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

    private func setupDataSource() {
        let weekSummaryRegistration = weekSummaryCellRegistration()
        let monthSummaryRegistration = monthSummaryCellRegistration()
        let walkingHeaderRegistration = createWalkingHeaderRegistration()
        let walkingFilterRegistration = createWalkingFilterRegistration()

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
            }
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<PersonalContent.Section, PersonalContent.Item>()
        snapshot.appendSections([.weekSummary, .walkingHeader, .walkingFilter])
        snapshot.appendItems([.weekSummaryItem, .monthSummaryItem], toSection: .weekSummary)
        snapshot.appendItems([.walkingHeaderItem], toSection: .walkingHeader)
        snapshot.appendItems([.walkingFilterItem], toSection: .walkingFilter)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

extension PersonalViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) { }
}
