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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout = self.createLayout()
            self.collectionView.reloadData() // clipping 방지
        })
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, env in
            // iPad라 해도 분할 화면(Split View)이나 멀티태스킹 시
            // 화면 폭이 좁아질 수 있으므로, 최소 폭 조건(700pt 이상)일 때만 2열로 전환
            let isTwoColumn = env.traitCollection.horizontalSizeClass == .regular
            && env.container.effectiveContentSize.width >= 700
            let columns = isTwoColumn ? 2 : 1

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .estimated(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(300)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: Array(repeating: item, count: columns)
            )
            group.interItemSpacing = .fixed(UICollectionViewConstant.defaultItemInset)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: UICollectionViewConstant.defaultInset,
                leading: UICollectionViewConstant.defaultInset,
                bottom: UICollectionViewConstant.defaultInset,
                trailing: UICollectionViewConstant.defaultInset
            )
            section.interGroupSpacing = 50
            return section
        }
    }

    private func scrollToCurrentMonth() {
        let currentMonth = Date().month
        let indexPath = IndexPath(item: currentMonth - 1, section: 0)

        collectionView.scrollToItem(
            at: indexPath,
            at: .top,
            animated: false
        )
    }
}

extension CalendarViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
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
        let currentMonth = indexPath.item + 1
        cell.configure(year: currentYear, month: currentMonth)

        return cell
    }
}
