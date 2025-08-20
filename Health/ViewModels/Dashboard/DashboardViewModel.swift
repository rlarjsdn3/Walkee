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

    let anchorDate: Date

    private(set) var topIDs: [DashboardTopBarViewModel.ItemID] = []
    private(set) var topCells: [DashboardTopBarViewModel.ItemID: DashboardTopBarViewModel] = [:]

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

    ///
    private var shouldShowSummaryAndCharts: Bool {
        anchorDate.isEqual(with: .now)
    }

    private let alanService = AlanViewModel()
    @Injected private var goalStepService: GoalStepCountViewModel
    @Injected private var coreDataUserService: (any CoreDataUserService)
    @Injected private var healthService: (any HealthService)
    @Injected private var promptBuilderService: (any PromptBuilderService)

    ///
    init(anchorDate: Date = .now) {
        self.anchorDate = anchorDate
    }


    // MARK: - Build Layout

    func buildDashboardCells(for environment: DashboardEnvironment) {
        buildTopBarCell()
        buildStackCells()
        buildGoalRingCells()
        buildCardCells()

        // 대시보드가 오늘자 데이터를 보여준다면
        if shouldShowSummaryAndCharts {
            buildAlanSummaryCells()
            buildBarChartsCells(for: environment)
        }
    }

    private func buildTopBarCell() {
        let newIDs = [DashboardTopBarViewModel.ItemID()]

        var newCells: [DashboardTopBarViewModel.ItemID: DashboardTopBarViewModel] = [:]
        newIDs.forEach { id in
            newCells.updateValue(DashboardTopBarViewModel(itemID: id), forKey: id)
        }

        topIDs = newIDs
        topCells = newCells
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
            HealthInfoStackCellViewModel.ItemID(kind: .activeEnergyBurned),
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
            && environment.horizontalClassIsRegular
        {
            // 레이아웃 환경이 아이패드인 경우
            newIDs = [
                DashboardBarChartsCellViewModel.ItemID(kind: .daysBack(14)),
                DashboardBarChartsCellViewModel.ItemID(kind: .monthsBack(12)),
            ]
        } else {
            // 레이아웃 환경이 아이폰인 경우
            newIDs = [
                DashboardBarChartsCellViewModel.ItemID(kind: .daysBack(7)),
                DashboardBarChartsCellViewModel.ItemID(kind: .monthsBack(6)),
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
        let (age, _) = fetchCoreDataUser()

        let newIDs = [
            HealthInfoCardCellViewModel.ItemID(kind: .walkingSpeed),
            HealthInfoCardCellViewModel.ItemID(kind: .walkingStepLength),
            HealthInfoCardCellViewModel.ItemID(kind: .walkingAsymmetryPercentage),
            HealthInfoCardCellViewModel.ItemID(kind: .walkingDoubleSupportPercentage),
        ]

        var newCells: [HealthInfoCardCellViewModel.ItemID: HealthInfoCardCellViewModel] = [:]
        newIDs.forEach { id in
            newCells.updateValue(HealthInfoCardCellViewModel(itemID: id, age: age), forKey: id)
        }

        cardIDs = newIDs
        cardCells = newCells
    }
}


// MARK: - Load HKData

extension DashboardViewModel {

    func loadHKData() {
        loadAnchorDateForTopCell()
        loadHKDataForGoalRingCells()
        loadHKDataForStackCells()
        loadHKDataForCardCells()
        loadHKDataForBarChartsCells()

        // 대시보드가 오늘자 데이터를 보여준다면
        if shouldShowSummaryAndCharts {
            loadAlanAIResponseForSummaryCells()
        }
    }

    func loadAnchorDateForTopCell() {
        for (_, vm) in topCells {
            vm.renewalAnchorDate(.now)
        }
    }

    func loadHKDataForGoalRingCells() {
        let (_, goalStepCount) = fetchCoreDataUser()
        
        Task {
            for (_, vm) in self.goalRingCells {
                vm.setState(.loading)

                // 루프 진입 직후, 해당 특정 데이터에 대한 읽기 권한이 있는지 먼저 확인
                guard await healthService.checkHasReadPermission(for: .stepCount) else {
                    vm.setState(.denied)  // 건강 데이터에 대한 읽기 권한이 없다면 '⚠️읽기 권한이 없다'고 표시
                    continue
                }

                // 예외 발생 시, 해당 일자에 유효한 데이터가 기록되지 않은 것으로 간주
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
                } else {
                    // 유효한 데이터가 없다면 '0'으로 표시
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

                // 루프 진입 직후, 해당 특정 데이터에 대한 읽기 권한이 있는지 먼저 확인
                guard await healthService.checkHasReadPermission(for: id.kind.quantityTypeIdentifier) else {
                    vm.setState(.denied)  // 건강 데이터에 대한 읽기 권한이 없다면 '⚠️읽기 권한이 없다'고 표시
                    continue
                }

                // 지난 7일 간 라인 차트를 그리기 위해 30일 전 시간 구하기
                guard let startDate: Date = anchorDate.endOfDay().addingDays(-14) else {
                    vm.setState(.failure(nil))
                    continue
                }

                async let hkData = try? fetchStatisticsHKData(
                    for: id.kind.quantityTypeIdentifier,
                    from: anchorDate.startOfDay(),
                    to: anchorDate.endOfDay(),
                    options: .cumulativeSum,
                    unit: id.kind.unit
                )


                async let hkCollection = try? fetchStatisticsCollectionHKData(
                    for: id.kind.quantityTypeIdentifier,
                    from: startDate,
                    to: anchorDate.endOfDay(),
                    options: .cumulativeSum,
                    unit: id.kind.unit
                )

                let (data, collection) = await (hkData, hkCollection)

                // Note: `startDate`를 사용하는 이유는,
                // 데이터가 `2025-08-17 15:00 (KST 8/18 00:00)`부터 `2025-08-18 15:00 (KST 8/19 00:00)`까지의
                // 걸음 수 데이터를 나타내기 때문입니다.
                // 만약 `endDate`를 사용하면, 실제로는 8/18 데이터임에도 불구하고 잘못하면 8/19 데이터로 처리될 수 있습니다.
                // 이 동작은 다른 코드에서도 동일하게 적용됩니다.
                var charts: [InfoStackContent.Charts] = []
                if let collection = collection {
                    charts = collection.map { InfoStackContent.Charts(date: $0.startDate, value: $0.value) }
                } else {
                    // 유효한 데이터가 없다면 '빈 배열'로 표시
                    charts = []
                }

                var content: InfoStackContent
                if let data = data {
                    content = InfoStackContent(value: data.value, charts: charts)
                } else {
                    // 유효한 데이터가 없다면 '0'으로 표시
                    content = InfoStackContent(value: 0, charts: charts)
                }

                vm.setState(.success(content))
            }
        }
    }

    func loadHKDataForBarChartsCells() {
        Task {
            for (id, vm) in self.chartsCells {
                vm.setState(.loading)
                // 차트 유형에 따라 시작 날짜와 마지막 날짜 구하기
                guard let startDate = id.kind.startDate(anchorDate),
                      let endDate = id.kind.endDate(anchorDate)
                else {
                    vm.setState(.failure(nil))
                    continue
                }

                // 루프 진입 직후, 해당 특정 데이터에 대한 읽기 권한이 있는지 먼저 확인
                guard await healthService.checkHasReadPermission(for: .stepCount) else {
                    vm.setState(.denied)  // 건강 데이터에 대한 읽기 권한이 없다면 '⚠️읽기 권한이 없다'고 표시
                    continue
                }

                let hkCollection = try? await fetchStatisticsCollectionHKData(
                    for: .stepCount,
                    from: startDate,
                    to: endDate,
                    options: .cumulativeSum,
                    interval: id.kind.interval,
                    unit: .count()
                )

                var contents: DashboardChartsContents
                if let collection = hkCollection {
                    contents = collection.map {
                        DashboardChartsContent(date: $0.startDate, value: $0.value)
                    }

                    // 일부 날짜의 걸음 수가 '0'이라서 일부 데이터가 존재하지 않으면
                    if contents.count < id.kind.count {
                        let diff = { // 일자 또는 월을 기준으로 차이 구하기
                            switch id.kind {
                            case .daysBack:   return startDate.dayDiff(to: endDate)
                            case .monthsBack: return startDate.monthDiff(to: endDate)
                            }
                        }()

                        // 시작 날짜와 종료 날짜의 차이만큼 순회하고
                        for offset in 0..<diff {
                            guard let offsetDate = adding(byKind: id.kind, value: offset, to: startDate)
                            else { continue }

                            // 특정 날짜에 해당하는 데이터가 없다면
                            if contents.first(where: { $0.date.isEqual(with: offsetDate) }) == nil {
                                contents.append(DashboardChartsContent(date: offsetDate, value: 0.0))
                            }
                        }
                    }
                    contents.sort { $0.date < $1.date }
                } else {
                    // 유효한 데이터가 없다면 '⚠️데이터를 가져올 수 없다'고 표시
                    vm.setState(.failure(nil))
                    continue
                }

                vm.setState(.success(contents))
            }
        }
    }

    func loadAlanAIResponseForSummaryCells() {
        Task {
            for (_, vm) in self.summaryCells {
                vm.setState(.loading)
                do {
                    // 루프 진입 직후, 모든 건강 데이터에 대해 하나라도 읽기 권한이 있는지 먼저 확인
                    guard await healthService.checkHasAnyReadPermission() else {
                        vm.setState(.denied)  // 건강 데이터에 대한 읽기 권한이 없다면 '⚠️읽기 권한이 없다'고 표시
                        continue
                    }

                    if let message = try await requestAlanToSummarizeTodayActivity() {
                        vm.setState(.success(AlanContent(message: message)))
                    } else {
                        vm.setState(.failure(nil))
                    }
                    await alanService.resetAgentState()
                } catch {
                    // 네트워크 통신에 실패하면 '⚠️네트워크 통신에 실패했다'고 표시
                    vm.setState(.failure(error))
                }
            }
        }
    }

    func loadHKDataForCardCells() {
        Task {
            for (id, vm) in self.cardCells {
                vm.setState(.loading)

                // 루프 진입 직후, 해당 특정 데이터에 대한 읽기 권한이 있는지 먼저 확인
                guard await healthService.checkHasReadPermission(for: id.kind.quantityTypeIdentifier) else {
                    vm.setState(.denied)  // 해당 데이터에 대한 읽기 권한이 없다면 '⚠️읽기 권한이 없다'고 표시
                    continue
                }

                let hkData = try? await fetchStatisticsHKData(
                    for: id.kind.quantityTypeIdentifier,
                    from: anchorDate.startOfDay(),
                    to: anchorDate.endOfDay(),
                    options: .discreteAverage,
                    unit: id.kind.unit
                )

                var content: InfoCardContent
                if let data = hkData {
                    content = InfoCardContent(value: data.value)
                } else {
                    // 유효한 데이터가 없다면 '⚠️데이터를 가져올 수 없다'고 표시
                    vm.setState(.failure(nil))
                    continue
                }

                vm.setState(.success(content))
            }
        }
    }
}


// MARK: - Fetch CoreData

extension DashboardViewModel {

    func fetchCoreDataUser() -> (age: Int, goalStep: Int) {
        // ⚠️ 사용자 및 목표 걸음 수가 제대로 등록되어 있으면 않으면 크래시
        let user = try! coreDataUserService.fetchUserInfo()
//        let goalStepCount = goalStepService.goalStepCount(for: anchorDate.endOfDay())!
//        return (Int(user.age), Int(goalStepCount))

        // 🍓 온보딩 화면에서 '목표 걸음 수'를 입력 받기 전까지 임시 값 반환
        return (Int(user.age), 10_000)
    }
}

extension DashboardViewModel {

    @available(*, deprecated)
    func requestHKAutorizationIfNeeded() async throws -> Bool {
        return try await healthService.requestAuthorization()
    }

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

    func requestAlanToSummarizeTodayActivity() async throws -> String? {
        guard let prompt = try? await promptBuilderService.makePrompt(
            message: nil,
            context: nil,
            option: .dailySummary
        ) else { return nil }
        let response = await alanService.sendQuestion(prompt)
        return response
    }
}


fileprivate extension DashboardViewModel {

    ///
    func adding(byKind kind: BarChartsBackKind, value: Int, to date: Date) -> Date? {
        switch kind {
        case .daysBack:
            return Calendar.current.date(byAdding: .day, value: value, to: date)
        case .monthsBack:
            return Calendar.current.date(byAdding: .month, value: value, to: date)
        }
    }
}


fileprivate extension Array {

    func prefix(maxLength convertToArrayImmediately: Int) -> [Element] {
        Array(prefix(maxLength: convertToArrayImmediately))
    }
}
