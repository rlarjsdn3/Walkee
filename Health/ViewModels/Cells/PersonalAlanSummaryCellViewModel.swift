//
//  PersonalAlanSummaryCellViewModel.swift
//  Health
//
//  Created by juks86 on 8/18/25.
//

import UIKit
import Combine
import HealthKit

final class AIMonthlySummaryCellViewModel {
    @Injected(.healthService) private var healthService: HealthService
    @Injected private var promptBuilderService: (any PromptBuilderService)
    @Injected private var userService: (any CoreDataUserService)

    private var alanService = AlanViewModel()
    private var healthDataViewModel = HealthDataViewModel()

    private var cancellables = Set<AnyCancellable>()
    private static var todayCache: String?
    private static var cacheDate: String?
    private(set) var itemID: ItemID

    // 셀 식별자
    struct ItemID: Hashable {
        let id: UUID = UUID()
    }

    // 월간 요약 내용
    struct Content: Hashable, Equatable {
        let message: String
    }
    // 로딩 상태 관리
    let stateSubject = CurrentValueSubject<LoadState<Content>, Never>(.idle)

    // 상태 변화 퍼블리셔
    var statePublisher: AnyPublisher<LoadState<Content>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // 상태 변화 콜백
    var didChange: ((ItemID) -> Void)?

    // 초기화
    init(itemID: ItemID) {
        self.itemID = itemID

        // 포그라운드 진입 시 권한 재체크
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.loadMonthlySummary()
                }
            }
            .store(in: &cancellables)

        // 날짜 변경 감지 설정 (자정 넘어갈 때)
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .sink { [weak self] _ in
                Task {
                    await self?.loadMonthlySummary()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                Task {
                    if UserDefaultsWrapper.shared.healthkitLinked {
                        // 연동 ON
                        await self?.loadMonthlySummary()
                    } else {
                        // 연동 OFF
                        await MainActor.run {
                            self?.setState(.denied)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    // 상태 업데이트
    func setState(_ new: LoadState<Content>) {
        stateSubject.send(new)
        didChange?(itemID)
    }
}

// MARK: - 월간 요약 로딩 로직
extension AIMonthlySummaryCellViewModel {

    /// 월간 요약을 로딩합니다 (HealthDataViewModel 재사용)
    @MainActor
    func loadMonthlySummary() async {

        guard UserDefaultsWrapper.shared.healthkitLinked else {
            setState(.denied)
            return
        }

        setState(.loading)

        // 권한 체크
        async let stepPermission = healthService.checkHasReadPermission(for: .stepCount)
        async let distancePermission = healthService.checkHasReadPermission(for: .distanceWalkingRunning)
        async let caloriesPermission = healthService.checkHasReadPermission(for: .activeEnergyBurned)

        let results = await (stepPermission, distancePermission, caloriesPermission)

        guard results.0 && results.1 && results.2 else {
            setState(.denied)
            return
        }

        // UserDefaultsWrapper로 캐시 확인
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        if UserDefaultsWrapper.shared.aiSummaryDate == today,
           let cached = UserDefaultsWrapper.shared.aiSummaryMessage {
            setState(.success(Content(message: cached)))
            return
        }

        do {
            // HealthDataViewModel의 getMonthlyHealthData() 호출
            let monthlyData = await healthDataViewModel.getMonthlyHealthData()

            // 사용자 정보 가져오기
            let userInfo = try userService.fetchUserInfo()

            // PromptContext 직접 생성
            let context = createPromptContext(userInfo: userInfo, monthlyData: monthlyData)

            // 생성된 context로 프롬프트 생성
            let aiPrompt = try await promptBuilderService.makePrompt(
                message: nil,
                context: context,
                option: .monthlySummary
            )

            // alanService로 AI 요청
            let summaryMessage = await alanService.sendQuestion(aiPrompt)

            // 응답 확인
            guard let summaryMessage = summaryMessage, !summaryMessage.isEmpty else {
                let error = NSError(domain: "AIError", code: 0, userInfo: nil)
                setState(.failure(error))
                return
            }

            // UserDefaultsWrapper로 캐시 저장
            UserDefaultsWrapper.shared.aiSummaryMessage = summaryMessage
            UserDefaultsWrapper.shared.aiSummaryDate = today

            // Content 생성 및 성공 상태로 변경
            let content = Content(message: summaryMessage)
            setState(.success(content))

        } catch {
            setState(.failure(error))
        }
    }

    // MARK: - Private Methods

    // HealthDataViewModel의 데이터로 PromptContext 생성
    private func createPromptContext(
        userInfo: UserInfoEntity,
        monthlyData: MonthlyHealthData
    ) -> PromptContext {

        // 목표 걸음수 찾기
        let goalStepCount = latestGoalStepCount(from: userInfo) ?? 0

        let descriptor = PromptDescriptor(
            // 사용자 기본 정보
            age: Int(userInfo.age),
            gender: userInfo.gender ?? "unspecified",
            weight: userInfo.weight,
            height: userInfo.height,
            diseases: userInfo.diseases,
            goalStepCount: goalStepCount, // 현재 목표 걸음수 미구현

            // 월간 데이터만 사용
            stepCount: Double(monthlyData.monthlyTotalSteps),      // 월간 총 걸음수
            distanceWalkingRunning: monthlyData.monthlyTotalDistance, // 월간 총 거리
            activeEnergyBurned: monthlyData.monthlyTotalCalories     // 월간 총 칼로리
        )

        return PromptContext(descriptor: descriptor)
    }

    // 최신 목표 걸음수 찾기
    private func latestGoalStepCount(from userInfo: UserInfoEntity) -> Int? {
        guard let set = userInfo.goalStepCount as? Set<GoalStepCountEntity> else { return nil }

        let candidate = set
            .max {
                let l = $0.effectiveDate ?? .distantPast
                let r = $1.effectiveDate ?? .distantPast
                return l < r
            }

        return candidate.map { Int($0.goalStepCount) }
    }
}
