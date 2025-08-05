import UIKit

final class CalendarViewController: CoreGradientViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        collectionView.performBatchUpdates(nil) { _ in
            self.scrollToCurrentMonth()
        }
    }

    override func setupAttribute() {
        super.setupAttribute()

        applyBackgroundGradient(.midnightBlack)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.register(
            CalendarMonthCell.nib,
            forCellWithReuseIdentifier: CalendarMonthCell.id
        )
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            // TODO: 실제 컨텐츠 높이에 따라 유동적으로 설정
            heightDimension: .estimated(400)
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
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func scrollToCurrentMonth() {
        let currentMonth = Date().month
        let indexPath = IndexPath(item: 0, section: currentMonth - 1)

        collectionView.scrollToItem(
            at: indexPath,
            at: .top,
            animated: false
        )
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
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarMonthCell.id,
            for: indexPath
        ) as? CalendarMonthCell else {
            fatalError("Failed to dequeue CalendarMonthCell")
        }

        let today = Date()
        let currentYear = today.year
        let currentMonth = indexPath.section + 1
        cell.configure(year: currentYear, month: currentMonth)

        return cell
    }
}
