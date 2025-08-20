//
//  WeekSummaryCell.swift
//  Health
//
//  Created by juks86 on 8/7/25.
//

import UIKit
import Combine

class WeekSummaryCell: CoreCollectionViewCell {

    @IBOutlet weak var weekBackgroundView: UIView!
    @IBOutlet weak var walkingLabel: UILabel!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var weekSummaryLabel: UILabel!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!

    private var barChartView: BarChartsView?
    private let viewModel = WeekSummaryCellViewModel()
    private var cancellables = Set<AnyCancellable>()

    //기존 생성자 제거하고 기본 초기화만 사용
    @MainActor required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        bindViewModel()
    }

    override func setupAttribute() {
        super.setupAttribute()
        CustomLightModeBoxConstraint.setupShadow(for: self)
        CustomLightModeBoxConstraint.setupDarkModeBorder(for: weekBackgroundView)
        weekBackgroundView.applyCornerStyle(.medium)

        viewModel.loadWeeklyData()
    }

    override func setupConstraints() {
        super.setupConstraints()
        CustomLightModeBoxConstraint.updateBackgroundHeight(constraint: backgroundHeight, in: self)

        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            CustomLightModeBoxConstraint.updateBackgroundHeight(constraint: self.backgroundHeight, in: self)
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

    // MARK: - UI 업데이트

    private func updateUI(for state: WeekSummaryCellViewModel.LoadState) {
        switch state {
        case .idle:
            hidePermissionView()

        case .loading:
            hidePermissionView()

        case .success(let data):
            hidePermissionView()
            configureChart(weeklySteps: data.dailySteps)
            updateUIWithData(data)

        case .denied:
            showPermissionView()

        case .failure:
            hidePermissionView()
        }
    }

    private func updateUIWithData(_ data: WeeklyHealthData) {
        // 걸음수 스타일링
        let stepsString = "\(data.weeklyTotalSteps.formatted()) 걸음"
        let stepsAttrString = NSAttributedString(string: stepsString)
            .font(.preferredFont(forTextStyle: .footnote), to: "걸음")
            .foregroundColor(.secondaryLabel, to: "걸음")
        walkingLabel.attributedText = stepsAttrString

        // 거리 스타일링
        let distanceString = "\(String(format: "%.1f", data.weeklyTotalDistance)) km"
        let distanceAttrString = NSAttributedString(string: distanceString)
            .font(.preferredFont(forTextStyle: .footnote), to: "km")
            .foregroundColor(.secondaryLabel, to: "km")
        distanceLabel.attributedText = distanceAttrString
    }

    // MARK: - 권한 요청 뷰

    private func showPermissionView() {
        if weekBackgroundView.subviews.contains(where: { $0 is PermissionDeniedFullView }) {
            return
        }

        let permissionView = PermissionDeniedFullView()
        weekBackgroundView.addSubview(permissionView)

        permissionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            permissionView.topAnchor.constraint(equalTo: weekBackgroundView.topAnchor),
            permissionView.leadingAnchor.constraint(equalTo: weekBackgroundView.leadingAnchor),
            permissionView.trailingAnchor.constraint(equalTo: weekBackgroundView.trailingAnchor),
            permissionView.bottomAnchor.constraint(equalTo: weekBackgroundView.bottomAnchor)
        ])

        permissionView.touchHandler = { [weak self] in
            Task {
                await self?.viewModel.requestPermission()
            }
        }
    }

    private func hidePermissionView() {
        weekBackgroundView.subviews.forEach { subview in
            if subview is PermissionDeniedFullView {
                subview.removeFromSuperview()
            }
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
        viewModel.loadWeeklyData()
    }
}
