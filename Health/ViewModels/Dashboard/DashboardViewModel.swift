//
//  DashboardViewModel.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import HealthKit

final class DashboardViewModel {
    
    ///
    struct DashboardEnvironment {
        let vericalClassIsRegular: Bool
        let horizontalClassIsRegular: Bool
    }

    private(set) var anchorDate: Date

    private(set) var goalRingIDs: [DailyGoalRingCellViewModel.ItemID] = []
    private(set) var goalRingCells: [DailyGoalRingCellViewModel.ItemID: DailyGoalRingCellViewModel] = [:]

    private(set) var stackIDs: [HealthInfoStackCellViewModel.ItemID] = []
    private(set) var stackCells: [HealthInfoStackCellViewModel.ItemID: HealthInfoStackCellViewModel] = [:]

    private(set) var summaryIDs: [AlanActivitySummaryCellViewModel.ItemID] = []
    private(set) var summaryCells: [AlanActivitySummaryCellViewModel.ItemID: AlanActivitySummaryCellViewModel] = [:]

    private(set) var cardIDs: [HealthInfoCardCellViewModel.ItemID] = []
    private(set) var cardCells: [HealthInfoCardCellViewModel.ItemID: HealthInfoCardCellViewModel] = [:]
    
    private(set) var chartsIDs: [DashboardBarChartsCellViewModel.ItemID] = []
    private(set) var chartsCells: [DashboardBarChartsCellViewModel.ItemID: DashboardBarChartsCellViewModel] = [:]

    // TODO: - Alan 서버에서 요약문을 가져오는 서비스 객체 주입하기
    // TODO: - 코어 데이터에서 사용자 정보 가져오는 서비스 객체 주입하기
    @Injected private var healthService: HealthService

    ///
    init(anchorDate: Date = .now) {
        self.anchorDate = anchorDate
    }

    ///
    func buildDashboardCells(for environment: DashboardEnvironment) {
        buildGoalRingCells()
        buildAlanSummaryCells()
        buildStackCells()
        buildCardCells()
        buildBarChartsCells(for: environment)
    }

    private func buildGoalRingCells() {
        let newIDs = [DailyGoalRingCellViewModel.ItemID()]

        var newCells: [DailyGoalRingCellViewModel.ItemID: DailyGoalRingCellViewModel] = [:]
        newIDs.forEach { id in
            newCells.updateValue(DailyGoalRingCellViewModel(itemID: id), forKey: id)
        }

        goalRingIDs = newIDs
        goalRingCells = newCells
    }

    private func buildStackCells() {
        let newIDs = [
            HealthInfoStackCellViewModel.ItemID(kind: .distanceWalkingRunning),
            HealthInfoStackCellViewModel.ItemID(kind: .appleExerciseTime),
            HealthInfoStackCellViewModel.ItemID(kind: .activeEnergyBurned)
        ]

        var newCells: [HealthInfoStackCellViewModel.ItemID: HealthInfoStackCellViewModel] = [:]
        newIDs.forEach { id in
            newCells.updateValue(HealthInfoStackCellViewModel(itemID: id), forKey: id)
        }

        stackIDs = newIDs
        stackCells = newCells
    }

    private func buildBarChartsCells(for environment: DashboardEnvironment) {
        var newIDs: [DashboardBarChartsCellViewModel.ItemID] = []
        if environment.vericalClassIsRegular
            && environment.horizontalClassIsRegular {
            // 레이아웃 환경이 아이패드인 경우
            newIDs = [
                DashboardBarChartsCellViewModel.ItemID(kind: .daysBack(14)),
                DashboardBarChartsCellViewModel.ItemID(kind: .monthsBack(12))
            ]
        } else {
            // 레이아웃 환경이 아이폰인 경우
            newIDs = [
                DashboardBarChartsCellViewModel.ItemID(kind: .daysBack(7)),
                DashboardBarChartsCellViewModel.ItemID(kind: .monthsBack(12))
            ]
        }

        var newCells: [DashboardBarChartsCellViewModel.ItemID: DashboardBarChartsCellViewModel] = [:]
        newIDs.forEach { id in
            newCells.updateValue(DashboardBarChartsCellViewModel(itemID: id), forKey: id)
        }

        chartsIDs = newIDs
        chartsCells = newCells
    }

    private func buildAlanSummaryCells() {
        let newIDs = [
            AlanActivitySummaryCellViewModel.ItemID()
        ]

        var newCells: [AlanActivitySummaryCellViewModel.ItemID: AlanActivitySummaryCellViewModel] = [:]
        newIDs.forEach { id in
            newCells.updateValue(AlanActivitySummaryCellViewModel(itemID: id), forKey: id)
        }

        summaryIDs = newIDs
        summaryCells = newCells
    }

    private func buildCardCells() {
        let (age, _) = fetchCoreDataUserInfo()
        
        let newIDs = [
            HealthInfoCardCellViewModel.ItemID(kind: .walkingSpeed),
            HealthInfoCardCellViewModel.ItemID(kind: .walkingStepLength),
            HealthInfoCardCellViewModel.ItemID(kind: .walkingAsymmetryPercentage),
            HealthInfoCardCellViewModel.ItemID(kind: .walkingDoubleSupportPercentage)
        ]
        
        var newCells: [HealthInfoCardCellViewModel.ItemID: HealthInfoCardCellViewModel] = [:]
        newIDs.forEach { id in
            newCells.updateValue(HealthInfoCardCellViewModel(itemID: id, age: age), forKey: id)
        }
        
        cardIDs = newIDs
        cardCells = newCells
    }
}

extension DashboardViewModel {

    func loadHKData() {
        loadHKDataForGoalRingCells()
        loadHKDataForStackCells()
        loadAlanAIResponseForSummaryCells()
        loadHKDataForCardCells()
        loadHKDataForBarChartsCells()
    }

    func loadHKDataForGoalRingCells() {
        let (_, goalStepCount) = fetchCoreDataUserInfo()

        Task {
            for (_, vm) in self.goalRingCells {
                vm.setState(.loading)

                // 루프를 돌기 전에 먼저 접근 권한이 있는지 확인하고 없으면 예외 처리
//                guard healthService.checkHasReadPermission() else {
//                    throw HKError(.errorAuthorizationDenied)
//                    continue
//                }

                // 여기서는 접근권한이 있으니 nil을 반환하면 그냥 해당 일자에 데이터가 없는 것으로 간주
                let hkData = try? await fetchStatisticsHKData(
                    for: .stepCount,
                    from: anchorDate.startOfDay(),
                    to: anchorDate.endOfDay(),
                    options: .cumulativeSum,
                    unit: .count()
                )

                var content: GoalRingContent
                if let hkData = hkData {
                    content = GoalRingContent(
                        goalStepCount: goalStepCount,
                        currentStepCount: Int(hkData.value)
                    )
                } else { // 데이터가 그냥 없으면 0으로 표시
                    content = GoalRingContent(
                        goalStepCount: goalStepCount,
                        currentStepCount: 0
                    )
                }
                vm.setState(.success(content))
            }
        }
    }

    func loadHKDataForStackCells() {
        Task {
            for (id, vm) in self.stackCells {
                vm.setState(.loading)
                // 지난 7일 간 라인 차트를 그리기 위해 7일 전 시간 구하기
                guard let startDate: Date = anchorDate.endOfDay().addingDays(-7) else {
                    vm.setState(.failure(HKError(.unknownError)))
                    continue
                }

                do {
                    let hkData = try await fetchStatisticsHKData(
                        for: id.kind.quantityTypeIdentifier,
                        from: anchorDate.startOfDay(),
                        to: anchorDate.endOfDay(),
                        options: .cumulativeSum,
                        unit: id.kind.unit
                    )

                    let collection = try await fetchStatisticsCollectionHKData(
                        for: id.kind.quantityTypeIdentifier,
                        from: startDate,
                        to: anchorDate.endOfDay(),
                        options: .cumulativeSum,
                        unit: id.kind.unit
                    )

                    let charts = collection.map { InfoStackContent.Charts(date: $0.endDate, value: $0.value) }
                    let content = InfoStackContent(value: hkData.value, charts: charts)

                    vm.setState(.success(content))
                } catch {
                    vm.setState(.failure(HKError(.unknownError)))
                }
            }
        }
    }

    func loadHKDataForBarChartsCells() {
        Task {
            for (id, vm) in self.chartsCells {
                vm.setState(.loading)
                //
                guard let startDate = id.kind.startDate(anchorDate),
                      let endDate = id.kind.endDate(anchorDate) else {
                    vm.setState(.failure(HKError(.unknownError)))
                    continue
                }

                do {
                    let collection = try await fetchStatisticsCollectionHKData(
                        for: .stepCount,
                        from: startDate,
                        to: endDate,
                        options: .cumulativeSum,
                        interval: id.kind.interval,
                        unit: .count()
                    )

                    let contents = collection.map { DashboardChartsContent(date: $0.endDate, value: $0.value) }
                    vm.setState(.success(contents))
                } catch {
                    vm.setState(.failure(HKError(.unknownError)))
                }
            }
        }
    }

    func loadAlanAIResponseForSummaryCells() {
        // TODO: - 앨런 프롬프트 작성에 필요한 건강 데이터 불러오기

        Task {
            for (_, vm) in self.summaryCells {
                vm.setState(.loading)
                do {
                    let message = try await requestAlanToSummarizeTodayActivity()
                    let content = AlanContent(message: message)
                    vm.setState(.success(content))
                } catch {
                    vm.setState(.failure(HKError(.unknownError)))
                }
            }
        }
    }

    func loadHKDataForCardCells() {
        Task {
            for (id, vm) in self.cardCells {
                vm.setState(.loading)

                do {
                    let hkData = try await fetchStatisticsHKData(
                        for: id.kind.quantityTypeIdentifier,
                        from: anchorDate.startOfDay(),
                        to: anchorDate.endOfDay(),
                        options: .mostRecent,
                        unit: id.kind.unit
                    )
                    print(hkData)

                    let content = InfoCardContent(value: hkData.value)
                    vm.setState(.success(content))
                } catch {
                    vm.setState(.failure(HKError(.unknownError)))
                }
            }
        }
    }
}

extension DashboardViewModel {

    ///
    func fetchCoreDataUserInfo() -> (age: Int, goalStep: Int) {
        (27, 10_000) // TODO: - 사용자 목표 걸음 수를 가져오는 코드 작성하기
    }
}

extension DashboardViewModel {

    ///
    @available(*, deprecated)
    func requestHKAutorizationIfNeeded() async throws -> Bool {
        return try await healthService.requestAuthorization()
    }

    ///
    func fetchStatisticsHKData(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions = .cumulativeSum,
        unit: HKUnit
    ) async throws -> HKData {
        try await healthService.fetchStatistics(
            for: identifier,
            from: startDate,
            to: endDate,
            options: options,
            unit: unit
        )
    }

    ///
    func fetchStatisticsCollectionHKData(
        for identifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions,
        interval intervalComponents: DateComponents = .init(day: 1),
        unit: HKUnit
    ) async throws -> [HKData] {
        return try await healthService.fetchStatisticsCollection(
            for: identifier,
            from: startDate,
            to: anchorDate.endOfDay(),
            options: options,
            interval: intervalComponents,
            unit: unit
        )
    }
}

extension DashboardViewModel {

    func requestAlanToSummarizeTodayActivity() async throws -> String {
        // TODO: - Alan AI에게 오늘 활동 요약 묻는 로직 작성하기
        """
        Lorem Ipsum is simply dummy text of the printing and typesetting industry.
        Lorem Ipsum has been the industry's standard dummy text ever since the 1500s,
        when an unknown printer took a galley of type and scrambled it to make a type specimen book.
        """
    }
}
