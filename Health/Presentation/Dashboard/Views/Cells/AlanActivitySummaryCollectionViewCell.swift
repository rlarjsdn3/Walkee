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

    override func setupAttribute() {
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

    func configure(with viewModel: AlanViewModel) {
        viewModel.didReceiveResponseText = { [weak self] text in
            self?.summaryLabel.text = text
            self?.didReceiveSummaryMessage?(text)
        }

        // TODO: - 프롬프트 설계하기
        Task {
            await viewModel.sendQuestion("안녕하세요! 오늘 서울 날씨와 폭염 지수를 알려주세요. 100자 이내로만 대답해주세요.")
        }
    }
}
