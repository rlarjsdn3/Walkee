import UIKit

final class CalendarViewController: CoreGradientViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private let calendarVM = CalendarViewModel()

    /// 첫 번째 스크롤(현재 월로 이동) 완료 여부를 나타내는 플래그
    private var didScrollToCurrent = false

    /// 초기 스크롤이 완전히 완료되었는지 나타내는 플래그 (무한 스크롤 허용 조건)
    private var didFinishInitialScroll = false

    override func setupAttribute() {
        super.setupAttribute()
		configureBackground()
        configureCollectionView()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 이미 초기 스크롤을 한 상태에서만 실행
        if didScrollToCurrent {
            scrollToCurrentMonth()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 최초 1회만 현재 월로 스크롤하고 무한 스크롤 활성화
        if !didScrollToCurrent {
            scrollToCurrentMonth()
            didScrollToCurrent = true
            didFinishInitialScroll = true
        }
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
            // 아이패드 등 큰 화면에서는 2열, 그 외에는 1열로 표시
            let isTwoColumn = env.traitCollection.horizontalSizeClass == .regular
            && env.container.effectiveContentSize.width >= 700
            let columns: CGFloat = isTwoColumn ? 2 : 1

            // 섹션 및 아이템 간격 설정
            let sectionInset = UICollectionViewConstant.defaultInset
            let itemInset = UICollectionViewConstant.defaultItemInset

            // 각 열의 가용 너비 계산
            let totalWidth = env.container.effectiveContentSize.width
            let availableWidth = totalWidth - (sectionInset * 2) - (isTwoColumn ? itemInset : 0)
            let columnWidth = availableWidth / columns

            // 월 셀의 높이 계산 (헤더 + 요일 + 날짜 영역)
            let headerHeight: CGFloat = 28
            let weekdayHeight: CGFloat = 20
            let verticalSpacing: CGFloat = 16 * 2
            let daySize: CGFloat = columnWidth / 7.0
            let numberOfRows: CGFloat = 6 // 고정
            let monthCellHeight = headerHeight + weekdayHeight + verticalSpacing + daySize * numberOfRows

            // 아이템 크기 설정 (너비는 비율, 높이는 절대값)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / columns),
                heightDimension: .absolute(monthCellHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // 그룹 크기 설정 (전체 너비, 계산된 높이)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(monthCellHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: Array(repeating: item, count: Int(columns))
            )
            group.interItemSpacing = .fixed(itemInset)

            // 섹션 설정 (여백 및 그룹 간 간격)
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: sectionInset,
                leading: sectionInset,
                bottom: sectionInset,
                trailing: sectionInset
            )
            section.interGroupSpacing = 50
            return section
        }
    }

    private func scrollToCurrentMonth() {
        if let indexPath = calendarVM.indexOfCurrentMonth() {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }
}

private extension CalendarViewController {

    func configureBackground() {
        applyBackgroundGradient(.midnightBlack)
    }

    func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.register(
            CalendarMonthCell.nib,
            forCellWithReuseIdentifier: CalendarMonthCell.id
        )
    }

    func bindViewModel() {
        calendarVM.onDataChanged = { [weak self] changes in
            Task { @MainActor in
                self?.handleDataChanges(changes)
            }
        }
    }

    // 뷰모델에서 전달받은 데이터 변경사항을 UI에 반영
    /// - Parameter changes: 변경 유형 (상단삽입, 하단삽입, 전체리로드)
    func handleDataChanges(_ changes: CalendarDataChanges) {
        switch changes {
            case .topInsert(let indexPaths):
                handleTopInsert(indexPaths: indexPaths)
            case .bottomInsert(let indexPaths):
                handleBottomInsert(indexPaths: indexPaths)
            case .reload:
                collectionView.reloadData()
        }
    }

    /// 상단에 새로운 월 데이터 삽입 시 UI 업데이트 및 스크롤 위치 보정
    /// - Parameter indexPaths: 삽입할 아이템들의 IndexPath 배열
    func handleTopInsert(indexPaths: [IndexPath]) {
        // 현재 화면에 보이는 첫 번째 아이템의 위치 저장 (스크롤 위치 보정용)
        guard let firstVisible = collectionView.indexPathsForVisibleItems.min() else { return }

        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: indexPaths)
            } completion: { _ in
                // 기존에 보던 아이템이 새로 삽입된 아이템 수만큼 뒤로 밀린 새 위치 계산
                let shifted = IndexPath(
                    item: firstVisible.item + indexPaths.count,
                    section: firstVisible.section
                )

                // 계산된 위치가 유효한지 확인 후 스크롤
                if shifted.item < self.collectionView.numberOfItems(inSection: shifted.section) {
                    self.collectionView.scrollToItem(at: shifted, at: .top, animated: false)
                }
            }
        }
    }

    /// 하단에 새로운 월 데이터 삽입 시 UI 업데이트
    /// - Parameter indexPaths: 삽입할 아이템들의 IndexPath 배열
    /// - Note: 하단 삽입은 현재 스크롤 위치에 영향을 주지 않으므로 별도 보정 불필요
    func handleBottomInsert(indexPaths: [IndexPath]) {
        collectionView.performBatchUpdates {
            collectionView.insertItems(at: indexPaths)
        }
    }
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarVM.monthsCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarMonthCell.id,
            for: indexPath
        ) as? CalendarMonthCell else {
            fatalError("Failed to dequeue CalendarMonthCell")
        }

        let monthData = calendarVM.month(at: indexPath.item)
        cell.configure(with: monthData)

        return cell
    }
}

extension CalendarViewController: UICollectionViewDelegate {

    /// 스크롤 시 무한 스크롤 처리 (상단/하단 임계점 도달 시 추가 데이터 로드)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 초기 스크롤이 완료되기 전에는 무한 스크롤 비활성화
        guard didFinishInitialScroll else { return }

        let loadThreshold: CGFloat = 200
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        // 상단 근처 스크롤 시 과거 데이터 로드
        if offsetY < loadThreshold {
            Task {
                await calendarVM.loadMoreTop()
            }
        }

        // 허단 근처 스크롤 시 미래 데이터 로드
        if offsetY > contentHeight - visibleHeight - loadThreshold {
            Task {
                await calendarVM.loadMoreBottom()
            }
        }
    }
}
