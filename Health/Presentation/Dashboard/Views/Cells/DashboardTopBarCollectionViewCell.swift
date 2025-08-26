//
//  DashboardTopBarCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import Combine
import UIKit

final class DashboardTopBarCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var weekDayLabel: UILabel!
    @IBOutlet weak var anchorDateLabel: UILabel!

    private var cancellables: Set<AnyCancellable> = []

    private var viewModel: DashboardTopBarViewModel!

    override func prepareForReuse() {
        cancellables.removeAll()
        anchorDateLabel.text = nil
    }

    override func setupAttribute() {
        anchorDateLabel.text = nil
    }
}

extension DashboardTopBarCollectionViewCell {

    func bind(with viewModel: DashboardTopBarViewModel) {
        self.viewModel = viewModel

        viewModel.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in self?.update(with: date) }
            .store(in: &cancellables)
    }

    private func update(with date: Date) {
        dateLabel.text = date.formatted(using: .md)
        weekDayLabel.text = date.formatted(using: .weekday)

        if date.isEqual(with: .now) {
            anchorDateLabel.text = "\(Date.now.formatted(using: .aHHmm)) 기준"
        }
    }
}
