//
//  DashboardViewModel.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import HealthKit

final class DashboardViewModel {

    private(set) var anchorDate: Date

    private(set) var stackIDs: [HealthInfoStackCellViewModel.ItemID] = []
    private(set) var stackCells: [HealthInfoStackCellViewModel.ItemID: HealthInfoStackCellViewModel] = [:]
    
    private(set) var cardIDs: [HealthInfoCardCellViewModel.ItemID] = []
    private(set) var cardCells: [HealthInfoCardCellViewModel.ItemID: HealthInfoCardCellViewModel] = [:]

    // TODO: - Alan 서버에서 요약문을 가져오는 서비스 객체 주입하기
    // TODO: - 코어 데이터에서 사용자 정보 가져오는 서비스 객체 주입하기
    @Injected private var healthService: HealthService

    ///
    init(anchorDate: Date = .now) {
        self.anchorDate = anchorDate
    }

    ///
    func buildDashboardCells() {
        buildStackCells()
        buildCardCells()
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
        loadHKDataForStackCells()
        loadHKDataForCardCells()
    }

    func loadHKDataForStackCells() {
        Task {
            for (id, vm) in self.stackCells {
                vm.setState(.loading)
                // 지난 7일 간 라인 차트를 그리기 위해 7일 전 시간 구하기
                guard let startDate: Date = .now.addingDays(-7) else {
                    vm.setState(.failure(HKError(.unknownError)))
                    continue
                }

                do {
                    let data = try await fetchStatisticsHKData(
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
                    
                    vm.setState(.success(data: data, collection: collection))
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
                    let data = try await fetchStatisticsHKData(
                        for: id.kind.quantityTypeIdentifier,
                        from: anchorDate.startOfDay(),
                        to: anchorDate.endOfDay(),
                        options: .mostRecent,
                        unit: id.kind.unit
                    )
                    
                    vm.setState(.success(data: data))
                } catch {
                    vm.setState(.failure(HKError(.unknownError)))
                }
            }
        }
    }
}

extension DashboardViewModel {

    ///
    func fetchCoreDataUserInfo() -> (age: Int, goalStep: Int ) {
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
            from: anchorDate.startOfDay(),
            to: anchorDate.endOfDay(),
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

    func requestAlanToSummarizeTodayActivity() async -> String {
        "" // TODO: - Alan AI에게 오늘 활동 요약 묻는 로직 작성하기
    }
}
