//
//  AISummaryCell.swift
//  Health
//
//  Created by juks86 on 8/10/25.
//

import UIKit

class AISummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var summaryBackgroundView: UIView!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setupAttribute() {
        super.setupAttribute()
        summaryBackgroundView.applyCornerStyle(.medium)
    }

    override func setupConstraints() {
        super.setupConstraints()
        
        updateBackgroundHeight()
    }

    // 기기와 방향에 따른 백그라운드 높이 조정
    private func updateBackgroundHeight() {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        let heightRatio: CGFloat

        if UIDevice.current.userInterfaceIdiom == .pad {
            if screenWidth > screenHeight {
                // iPad 가로: 더 작은 비율
                heightRatio = 0.18  // 18%
            } else {
                // iPad 세로: 기본 비율
                heightRatio = 0.20  // 25%
            }
        } else {
            // iPhone: 기본 비율
            heightRatio = 0.25
        }

        backgroundHeight.constant = screenHeight * heightRatio
    }

    // 회전 시 높이 업데이트
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        DispatchQueue.main.async {
            self.updateBackgroundHeight()

            // 애니메이션으로 부드럽게 변경
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }
}
