//
//  MonthSummaryCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit

class MonthSummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var monthlyBackgroungView: UIView!
    @IBOutlet weak var monthSummaryLabel: UILabel!
    @IBOutlet weak var walkingLabel: UILabel!
    @IBOutlet weak var walkingSubLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceSubLabel: UILabel!
    @IBOutlet weak var calorieLabel: UILabel!
    @IBOutlet weak var calorieSubLabel: UILabel!

    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setupAttribute() {
        super.setupAttribute()
        monthlyBackgroungView.applyCornerStyle(.medium)

        //현재 월 가져오기
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M" // 숫자 월

        let currentMonth = dateFormatter.string(from: Date())
        monthSummaryLabel.text = "\(currentMonth)월 기록 요약"
    }

    override func setupConstraints() {
         super.setupConstraints()

         // 🔥 초기 높이 설정
         updateBackgroundHeight()

         // 백그라운드뷰 너비 설정
         monthlyBackgroungView.translatesAutoresizingMaskIntoConstraints = false
         NSLayoutConstraint.activate([
             monthlyBackgroungView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
             monthlyBackgroungView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
         ])
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
