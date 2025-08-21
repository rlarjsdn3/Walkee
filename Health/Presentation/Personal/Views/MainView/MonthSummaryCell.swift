//
//  MonthSummaryCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit
import Combine

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
    
    private let viewModel = MonthSummaryCellViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // 생성자 제거하고 기본 초기화만 사용
    @MainActor required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bindViewModel()
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        BackgroundHeightUtils.setupShadow(for: self)
        BackgroundHeightUtils.setupDarkModeBorder(for: monthlyBackgroundView)
        monthlyBackgroundView.applyCornerStyle(.medium)
        
        //현재 월 가져오기
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M" // 숫자 월
        
        let currentMonth = dateFormatter.string(from: Date())
        monthSummaryLabel.text = "\(currentMonth)월 기록 요약"
        
        viewModel.loadMonthlyData()
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        BackgroundHeightUtils.updateBackgroundHeight(constraint: backgroundHeight, in: self)
        
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            BackgroundHeightUtils.updateBackgroundHeight(constraint: self.backgroundHeight, in: self)
        }
    }
    
    private func updateUI(for state: MonthSummaryCellViewModel.LoadState) {
        switch state {
        case .idle:
            hidePermissionView()
            
        case .loading:
            hidePermissionView()
            
        case .success(let data):
            hidePermissionView()
            updateUIWithData(with: data)
            
        case .denied:
            showPermissionView()
            
        case .failure:
            hidePermissionView()
        }
    }
    
    private func showPermissionView() {
        if monthlyBackgroundView.subviews.contains(where: { $0 is PermissionDeniedFullView }) {
            return
        }
        
        let permissionView = PermissionDeniedFullView()
        monthlyBackgroundView.addSubview(permissionView)
        
        permissionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            permissionView.topAnchor.constraint(equalTo: monthlyBackgroundView.topAnchor),
            permissionView.leadingAnchor.constraint(equalTo: monthlyBackgroundView.leadingAnchor),
            permissionView.trailingAnchor.constraint(equalTo: monthlyBackgroundView.trailingAnchor),
            permissionView.bottomAnchor.constraint(equalTo: monthlyBackgroundView.bottomAnchor)
        ])
        
        permissionView.touchHandler = { [weak self] in
            Task {
                await self?.viewModel.requestPermission()
            }
        }
    }
    
    private func hidePermissionView() {
        monthlyBackgroundView.subviews.forEach { subview in
            if subview is PermissionDeniedFullView {
                subview.removeFromSuperview()
            }
        }
    }
    
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(for: state)
            }
            .store(in: &cancellables)
    }
    
    // UI 업데이트 메서드
    private func updateUIWithData(with data: MonthlyHealthData) {
        // 메인 라벨 (총계)
        let stepsString = "\(data.monthlyTotalSteps.formatted()) 걸음"
        let stepsAttrString = NSAttributedString(string: stepsString)
            .font(.preferredFont(forTextStyle: .footnote), to: "걸음")
            .foregroundColor(.secondaryLabel, to: "걸음")
        walkingLabel.attributedText = stepsAttrString
        
        let distanceString = "\(String(format: "%.1f", data.monthlyTotalDistance)) km"
        let distanceAttrString = NSAttributedString(string: distanceString)
            .font(.preferredFont(forTextStyle: .footnote), to: "km")
            .foregroundColor(.secondaryLabel, to: "km")
        distanceLabel.attributedText = distanceAttrString
        
        let calorieString = "\(String(format: "%.1f", data.monthlyTotalCalories)) kcal"
        let calorieAttrString = NSAttributedString(string: calorieString)
            .font(.preferredFont(forTextStyle: .footnote), to: "kcal")
            .foregroundColor(.secondaryLabel, to: "kcal")
        calorieLabel.attributedText = calorieAttrString
        
        
        // 서브 라벨 (지난달 비교)
        walkingSubLabel.text = formatChange(
            difference: abs(data.stepsDifference),
            type: data.stepsChangeType,
            unit: "걸음"
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
        viewModel.loadMonthlyData()
    }
}

