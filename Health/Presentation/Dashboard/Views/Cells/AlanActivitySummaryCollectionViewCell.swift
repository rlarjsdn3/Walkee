//
//  AlanActivitySummaryCollectionViewCell.swift
//  Health
//
//  Created by 김건우 on 8/5/25.
//

import UIKit

final class AlanActivitySummaryCollectionViewCell: CoreCollectionViewCell {

    @IBOutlet weak var summaryLabel: UILabel!

    ///
    var didReceiveSummaryMessage: ((String) -> Void)?

    override func setupAttribute() { // TODO: - 대시보드 공통 Core 셀 구현하기
//       self.applyCornerStyle(.medium)
        self.backgroundColor = .boxBg
        self.layer.cornerRadius = 12 // medium
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.separator.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.05
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 5
        self.layer.borderWidth = (traitCollection.userInterfaceStyle == .dark) ? 0 : 1

        summaryLabel.numberOfLines = 5
        summaryLabel.minimumScaleFactor = 0.75
        summaryLabel.adjustsFontSizeToFitWidth = true

        registerForTraitChanges()
    }

    private func registerForTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            if self.traitCollection.userInterfaceStyle == .dark {
                self.layer.borderWidth = 0
            } else {
                self.layer.borderWidth = 1
            }
        }
    }
}

extension AlanActivitySummaryCollectionViewCell {

    // Note: - 본래 ViewModel에서 모든 데이터를 전달하는 게 맞으나,
    //
    func configure(with viewModel: AlanActivitySummaryCellViewModel) {
        Task {
            // TOOD: - HealthKit으로부터 사용자 건강 데이터 가져오기
            let message = await viewModel.askAlanToSummarizeActivity()
            self.summaryLabel.text = message
            didReceiveSummaryMessage?(message)
        }
    }
}
