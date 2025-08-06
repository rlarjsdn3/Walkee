//
//  SegmentControlCell.swift
//  Health
//
//  Created by juks86 on 8/5/25.
//

import UIKit

class AnalysisPeriodCell: CoreCollectionViewCell {

    @IBOutlet weak var rightChevronButton: UIButton!
    @IBOutlet weak var leftChevronButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var segmentControl: UISegmentedControl!

    private var isCurrentPeriod = true

    @IBAction func segmentButton(_ sender: Any) {

        isCurrentPeriod = true
        updateDateLabel()
        rightChevronButton.isHidden = true
    }

    @IBAction func leftChevron(_ sender: Any) {
        guard isCurrentPeriod else { return }

        isCurrentPeriod = false
        updateDateLabel()

        rightChevronButton.isHidden = false
    }

    @IBAction func rightChevron(_ sender: Any) {
        guard !isCurrentPeriod else { return }

        isCurrentPeriod = true
        updateDateLabel()

        rightChevronButton.isHidden = true
        print("오른쪽 클릭")
    }

    override func setupAttribute() {
        super.setupAttribute()

        updateDateLabel()

        rightChevronButton.isHidden = true
    }

    override func setupConstraints() {
        super.setupConstraints()

        segmentControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // 너비를 부모 뷰의 60%로 설정
            segmentControl.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.6)
        ])
    }

    private func updateDateLabel() {
        let isWeekly = segmentControl.selectedSegmentIndex == 0
        if isWeekly {
            //주간
            dateLabel.text = isCurrentPeriod ? "이번주" : "저번주"
        } else {
            //월간
            dateLabel.text = isCurrentPeriod ? "이번달" : "저번달"
        }
    }
}
