//
//  WeekSummaryCellViewModel.swift
//  Health
//
//  Created by juks86 on 8/17/25.
//

import UIKit
import Combine
import HealthKit

final class WeekSummaryCellViewModel: ObservableObject {

    // 상태관리
    enum LoadState {
        case idle
        case loading //스켈레톤 방식으로 처리(추후)
        case success(WeeklyHealthData)
        case denied    // 권한 없음 (걸음수 또는 거리 권한 중 하나라도 없음)
        case failure
    }

    @Published var state: LoadState = .idle

    @Injected(.healthService) private var healthService: HealthService
    private let healthDataViewModel = HealthDataViewModel()

    private static var cachedWeeklyData: WeeklyHealthData?
    private static var lastCacheTime: Date?
    private static let cacheTimeout: TimeInterval = 300 // 5분

    private var cancellables = Set<AnyCancellable>()

    init() {
        //  앱이 포그라운드로 돌아올 때 권한 재체크
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.loadWeeklyData()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                let isLinked = UserDefaultsWrapper.shared.healthkitLinked

                if isLinked {
                    // 연동 ON
                    self?.loadWeeklyData()
                } else {
                    // 연동 OFF
                    self?.state = .denied
                }
            }
            .store(in: &cancellables)
    }

    /// 주간 데이터 로드
    func loadWeeklyData() {
        state = .loading

        Task { @MainActor in

            //(걸음수 + 거리 둘 다 필요)
            let hasStepPermission = await healthService.checkHasReadPermission(for: .stepCount)
            let hasDistancePermission = await healthService.checkHasReadPermission(for: .distanceWalkingRunning)

            // 둘 다 허용되어야만 권한 있음
            let hasAllPermissions = hasStepPermission && hasDistancePermission

            guard hasAllPermissions else {
                state = .denied
                return
            }

            //캐시처리
            if let cached = Self.cachedWeeklyData,
               let lastTime = Self.lastCacheTime,
               Date().timeIntervalSince(lastTime) < Self.cacheTimeout {
                state = .success(cached)
                return
            }

            let weeklyData = await healthDataViewModel.getWeeklyHealthData()
            Self.cachedWeeklyData = weeklyData
            Self.lastCacheTime = Date()
            state = .success(weeklyData)
        }
    }

    /// 권한 요청
    func requestPermission() async -> Bool {
        do {
            _ = try await healthService.requestAuthorization()
        } catch {
        }

        // 권한 요청 후 다시 체크
        let hasStepPermission = await healthService.checkHasReadPermission(for: .stepCount)
        let hasDistancePermission = await healthService.checkHasReadPermission(for: .distanceWalkingRunning)
        let hasAllPermissions = hasStepPermission && hasDistancePermission

        if hasAllPermissions {
            // 권한 허용되면 자동으로 데이터 로드
            await MainActor.run {
                loadWeeklyData()
            }
        }
        return hasAllPermissions
    }
}
