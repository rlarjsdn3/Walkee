//
//  MonthSummaryCellViewModel.swift
//  Health
//
//  Created by juks86 on 8/17/25.
//

import UIKit
import Combine
import HealthKit

final class MonthSummaryCellViewModel: ObservableObject {

    //상태관리
    enum LoadState {
        case idle
        case loading
        case success(MonthlyHealthData)
        case denied    // 권한 없음
        case failure
    }

    @Published var state: LoadState = .idle

    // 의존성주입
    @Injected(.healthService) private var healthService: HealthService
    private let healthDataViewModel = HealthDataViewModel()

    private static var cachedMonthlyData: MonthlyHealthData?
    private static var lastCacheTime: Date?
    private static let cacheTimeout: TimeInterval = 86400 // 24시간 (하루)

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 앱이 포그라운드로 돌아올 때 권한 재체크
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.loadMonthlyData()
            }
            .store(in: &cancellables)
    }

    /// 월간 데이터 로드
    func loadMonthlyData() {
        state = .loading

        Task { @MainActor in
            // 권한 체크 (걸음수 + 거리 + 칼로리 모두 필요)
            let hasStepPermission = await healthService.checkHasReadPermission(for: .stepCount)
            let hasDistancePermission = await healthService.checkHasReadPermission(for: .distanceWalkingRunning)
            let hasCaloriesPermission = await healthService.checkHasReadPermission(for: .activeEnergyBurned)

            // 모두 허용되어야만 권한 있음
            let hasAllPermissions = hasStepPermission && hasDistancePermission && hasCaloriesPermission

            guard hasAllPermissions else {
                state = .denied
                return
            }

            // 캐시 확인 (24시간)
            if let cached = Self.cachedMonthlyData,
               let lastTime = Self.lastCacheTime,
               Date().timeIntervalSince(lastTime) < Self.cacheTimeout {
                state = .success(cached)
                return
            }

            let monthlyData = await healthDataViewModel.getMonthlyHealthData()
            Self.cachedMonthlyData = monthlyData
            Self.lastCacheTime = Date()
            state = .success(monthlyData)
        }
    }

    /// 권한 요청
    func requestPermission() async -> Bool {
        do {
            _ = try await healthService.requestAuthorization()
        } catch {
            print("권한 요청 실패")
        }

        // 권한 요청 후 다시 체크
        let hasStepPermission = await healthService.checkHasReadPermission(for: .stepCount)
        let hasDistancePermission = await healthService.checkHasReadPermission(for: .distanceWalkingRunning)
        let hasCaloriesPermission = await healthService.checkHasReadPermission(for: .activeEnergyBurned)
        let hasAllPermissions = hasStepPermission && hasDistancePermission && hasCaloriesPermission

        if hasAllPermissions {
            // 권한 허용되면 자동으로 데이터 로드
            await MainActor.run {
                loadMonthlyData()
            }
        }

        return hasAllPermissions
    }
}
