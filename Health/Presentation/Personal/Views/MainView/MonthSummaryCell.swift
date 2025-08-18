//
//  MonthSummaryCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit

class MonthSummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var monthlyBackgroundView: UIView!
    @IBOutlet weak var monthSummaryLabel: UILabel!
    @IBOutlet weak var walkingLabel: UILabel!
    @IBOutlet weak var walkingSubLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceSubLabel: UILabel!
    @IBOutlet weak var calorieLabel: UILabel!
    @IBOutlet weak var calorieSubLabel: UILabel!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!

    private static var cachedMonthlyData: MonthlyHealthData?
    private static var cacheDate: String?

    private let healthDataViewModel = HealthDataViewModel()

    // 생성자 제거하고 기본 초기화만 사용
    @MainActor required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setupAttribute() {
        super.setupAttribute()
        monthlyBackgroundView.applyCornerStyle(.medium)

        //현재 월 가져오기
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M" // 숫자 월

        let currentMonth = dateFormatter.string(from: Date())
        monthSummaryLabel.text = "\(currentMonth)월 기록 요약"

        loadMonthlyData()
    }

    override func setupConstraints() {
        super.setupConstraints()
        BackgroundHeightUtils.updateBackgroundHeight(constraint: backgroundHeight, in: self)

        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            BackgroundHeightUtils.updateBackgroundHeight(constraint: self.backgroundHeight, in: self)
        }
    }

    // 월간 데이터 로드 메서드
    private func loadMonthlyData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        // 같은 날이면 캐시 재사용
        if let cached = Self.cachedMonthlyData,
           let cacheDate = Self.cacheDate,
           cacheDate == today {

            updateUI(with: cached)
            return
        }

        // 새로운 날에만 네트워크 요청
        Task { @MainActor in
            let monthlyData = await healthDataViewModel.getMonthlyHealthData()
            Self.cachedMonthlyData = monthlyData
            Self.cacheDate = today
            updateUI(with: monthlyData)
        }
    }

    // UI 업데이트 메서드
    private func updateUI(with data: MonthlyHealthData) {
        // 메인 라벨 (총계)
        walkingLabel.text = "\(data.monthlyTotalSteps.formatted())보"
        distanceLabel.text = "\(String(format: "%.1f", data.monthlyTotalDistance))km"
        calorieLabel.text = "\(String(format: "%.1f", data.monthlyTotalCalories))kcal"

        // 서브 라벨 (지난달 비교)
        walkingSubLabel.text = formatChange(
            difference: abs(data.stepsDifference),
            type: data.stepsChangeType,
            unit: "보"
        )
        walkingSubLabel.textColor = data.stepsChangeType.color

        distanceSubLabel.text = formatChange(
            difference: abs(data.distanceDifference),
            type: data.distanceChangeType,
            unit: "km"
        )
        distanceSubLabel.textColor = data.distanceChangeType.color

        calorieSubLabel.text = formatChange(
            difference: abs(data.caloriesDifference),
            type: data.caloriesChangeType,
            unit: "kcal"
        )
        calorieSubLabel.textColor = data.caloriesChangeType.color
    }

    // 변화량 포맷팅
    private func formatChange(difference: Any, type: ChangeType, unit: String) -> String {
        let symbol = type.symbol

        if let intDiff = difference as? Int {
            return "지난달 대비 \(symbol) \(intDiff.formatted())\(unit)"
        } else if let doubleDiff = difference as? Double {
            return "지난달 대비 \(symbol) \(String(format: "%.1f", doubleDiff))\(unit)"
        }

        return "지난달 대비 \(symbol) 0\(unit)"
    }

    // 셀 재사용 준비
    override func prepareForReuse() {
        super.prepareForReuse()
        loadMonthlyData()
    }
}

