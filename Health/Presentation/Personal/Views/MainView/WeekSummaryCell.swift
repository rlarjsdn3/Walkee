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
    
    private var barChartView: BarChartsView?
    private static var cachedWeeklyData: WeeklyHealthData?
    private static var lastCacheTime: Date?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        weekBackgroundView.applyCornerStyle(.medium)
        loadWeeklyData()
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        BackgroundHeightUtils.updateBackgroundHeight(constraint: backgroundHeight, in: self)
        
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            BackgroundHeightUtils.updateBackgroundHeight(constraint: self.backgroundHeight, in: self)
        }
    }
    // MARK: - 차트 관련 메서드
    
    // 목표 걸음 수와 함께 차트를 설정합니다
    func configureChart(weeklySteps: [Int]) {
        
        // 기존 차트가 있다면 제거
        removeExistingChart()
        
        // 차트 데이터 생성 (목표 포함)
        let chartData = createChartData(from: weeklySteps)
        
        // 차트 스타일 설정
        let configuration = createChartConfiguration()
        
        // BarChartsView 생성 및 설정
        barChartView = BarChartsView(chartData: chartData, configuration: configuration)
        
        guard let barChartView = barChartView else {
            print("barChartView 생성 실패!")
            return
        }
        
        // chartView에 추가
        chartView.addSubview(barChartView)
        barChartView.translatesAutoresizingMaskIntoConstraints = false
        
        // 제약 조건 설정
        NSLayoutConstraint.activate([
            barChartView.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 0),
            barChartView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 16),
            barChartView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -16),
            barChartView.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 0)
        ])
    }
    
    // MARK: - Private Methods
    
    /// 기존에 추가된 차트를 제거합니다
    private func removeExistingChart() {
        barChartView?.removeFromSuperview()
        barChartView = nil
    }
    
    /// 목표 걸음 수를 포함한 차트 데이터를 생성합니다
    private func createChartData(from weeklySteps: [Int]) -> BarChartsView.ChartData {
        let calendar = Calendar.current
        let today = Date()
        
        // 오늘의 요일을 구합니다 (1=일요일, 2=월요일, ..., 7=토요일)
        let todayWeekday = calendar.component(.weekday, from: today)
        
        // 월요일 기준으로 변환 (0=월요일, 1=화요일, ..., 6=일요일)
        let mondayBasedWeekday = (todayWeekday == 1) ? 6 : todayWeekday - 2
        
        // 기본 요일 레이블
        let baseWeekdayLabels = ["월", "화", "수", "목", "금", "토", "일"]
        
        // 오늘이 마지막에 오도록 요일 레이블 재배열
        // 예: 오늘이 수요일(인덱스 2)이면 -> [목, 금, 토, 일, 월, 화, 수]
        var reorderedLabels: [String] = []
        var reorderedSteps: [Int] = []
        
        for i in 0..<7 {
            let index = (mondayBasedWeekday + 1 + i) % 7  // 오늘 다음날부터 시작
            reorderedLabels.append(baseWeekdayLabels[index])
            reorderedSteps.append(weeklySteps[index])
        }
        
        // 이번 주의 시작일 (월요일) 계산
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // 차트 요소들 생성 (재배열된 순서로)
        let elements = reorderedSteps.enumerated().map { displayIndex, steps in
            // 실제 날짜 계산을 위한 원래 인덱스
            let originalIndex = (mondayBasedWeekday + 1 + displayIndex) % 7
            let date = calendar.date(byAdding: .day, value: originalIndex, to: startOfWeek) ?? today
            
            return BarChartsView.ChartData.Element(
                value: Double(steps),
                xLabel: reorderedLabels[displayIndex], // 재배열된 레이블 사용
                date: date
            )
        }
        
        return BarChartsView.ChartData(elements: elements)
    }
    /// 차트의 스타일 설정을 생성합니다
    /// - Returns: 차트 Configuration
    private func createChartConfiguration() -> BarChartsView.Configuration {
        // 기기별 막대 너비 설정
        let barWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16
        
        return BarChartsView.Configuration(
            barWidth: barWidth,
            textStyle: BarChartsView.Configuration.TextStyle(
                xAxisLabelFont: .preferredFont(forTextStyle: .caption1),    // X축 라벨 (월, 화, 수...)
                xAxisLabelTint: .label,                          		    // X축 라벨 색상 (기본 텍스트 색)
                valueLabelFont: .preferredFont(forTextStyle: .caption1),    // 막대 위 걸음 수
                valueLabelTint: .label                                     // 막대 위 걸음 수 색상
            ),
            displayOptions: BarChartsView.Configuration.DisplayOptions(
                showValueLabel: true // 막대 위에 걸음 수 표시
            )
        )
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 셀이 재사용될 때 업데이트(5분간격)
        loadWeeklyData()
    }
    
    private func loadWeeklyData() {
        // 5분 이내 캐시가 있으면 재사용
        if let cached = Self.cachedWeeklyData,
           let lastTime = Self.lastCacheTime,
           Date().timeIntervalSince(lastTime) < 300 { // 5분
            
            updateUI(with: cached)
            return
        }
        
        // 새로 데이터 로드
        Task { @MainActor in
            let weeklyData = await HealthDataViewModel.shared.getWeeklyHealthData()
            Self.cachedWeeklyData = weeklyData
            Self.lastCacheTime = Date()
            updateUI(with: weeklyData)
        }
    }
    
    private func updateUI(with data: WeeklyHealthData) {
        
        configureChart(weeklySteps: data.dailySteps)
        walkingLabel.text = "\(data.weeklyTotalSteps.formatted())보"
        distanceLabel.text = "\(String(format: "%.1f", data.weeklyTotalDistance))km"
    }
}
