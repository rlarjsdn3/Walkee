import UIKit

final class CalendarViewController: CoreViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    override func setupAttribute() {
        super.setupAttribute()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createCompositionalLayout()
        collectionView.register(
            CalendarMonthCell.nib,
            forCellWithReuseIdentifier: CalendarMonthCell.id
        )
    }

    private func createCompositionalLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = itemSize
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: UICollectionViewConstant.defaultInset,
                leading: UICollectionViewConstant.defaultInset,
                bottom: UICollectionViewConstant.defaultInset,
                trailing: UICollectionViewConstant.defaultInset
            )
            return section
        }
    }
}

extension CalendarViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarMonthCell.id, for: indexPath) as? CalendarMonthCell else {
            fatalError("Failed to dequeue CalendarMonthCell")
        }

        let today = Date()
        let currentYear = today.year
        let currentMonth = indexPath.section + 1
        cell.configure(year: currentYear, month: currentMonth)

        return cell
    }
}
