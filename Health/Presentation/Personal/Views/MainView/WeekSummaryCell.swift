//
//  WeekSummaryCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit

class WeekSummaryCell: CoreCollectionViewCell {
    
    
    @IBOutlet weak var weekBackgroundView: UIView!
    @IBOutlet weak var walkingLabel: UILabel!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var weekSummaryLabel: UILabel!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setupAttribute() {
        super.setupAttribute()
        weekBackgroundView.applyCornerStyle(.medium)
    }

    override func setupConstraints() {
        super.setupConstraints()
        
        updateBackgroundHeight()
    }

    private func updateBackgroundHeight() {
          let screenHeight = UIScreen.main.bounds.height
          let screenWidth = UIScreen.main.bounds.width

          let heightRatio: CGFloat

          if UIDevice.current.userInterfaceIdiom == .pad {
              if screenWidth > screenHeight {
                  heightRatio = 0.18  // iPad 가로: 18%
              } else {
                  heightRatio = 0.20  // iPad 세로: 25%
              }
          } else {
              heightRatio = 0.25  // iPhone: 25%
          }

          backgroundHeight.constant = screenHeight * heightRatio
      }

      // 회전 시 업데이트
      override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
          super.traitCollectionDidChange(previousTraitCollection)

          DispatchQueue.main.async {
              self.updateBackgroundHeight()
              UIView.animate(withDuration: 0.3) {
                  self.layoutIfNeeded()
              }
          }
      }
  }

