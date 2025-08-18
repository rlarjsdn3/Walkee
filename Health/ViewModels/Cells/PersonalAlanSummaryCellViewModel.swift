//
//  PersonalAlanSummaryCellViewModel.swift
//  Health
//
//  Created by juks86 on 8/18/25.
//

import Combine
import HealthKit

final class AIMonthlySummaryCellViewModel {
    
    /// 로딩 상태
    enum LoadState<T> {
        case idle       // 대기 상태
        case loading    // 로딩 중
        case loaded(T)  // 성공 (데이터 포함)
        case failed(Error) // 실패 (에러 포함)
    }
    
    /// 셀 식별자
    struct ItemID: Hashable {
        let id: UUID = UUID()
    }
    
    /// 월간 요약 내용
    struct Content: Hashable {
        let message: String
    }
    
    // MARK: - 캐시 관리
    private static var lastLoadDate: Date?
    private static var cachedContent: Content?
    
    /// 셀 ID
    private(set) var itemID: ItemID
    
    /// 로딩 상태 관리
     let stateSubject = CurrentValueSubject<LoadState<Content>, Never>(.idle)
    
    /// 상태 변화 퍼블리셔
    var statePublisher: AnyPublisher<LoadState<Content>, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    /// 상태 변화 콜백
    var didChange: ((ItemID) -> Void)?
    
    /// 의존성들
    private lazy var alanService = AlanViewModel()
    private lazy var healthDataViewModel = HealthDataViewModel()
    
    @Injected private var promptBuilderService: (any PromptBuilderService)
    @Injected private var userService: (any CoreDataUserService)
    
    /// 초기화
    init(itemID: ItemID) {
        self.itemID = itemID
    }
    
    /// 상태 업데이트
    func setState(_ new: LoadState<Content>) {
        stateSubject.send(new)
        didChange?(itemID)
    }
    
    /// 캐시된 콘텐츠 반환 (셀에서 즉시 표시용)
    func getCachedContent() -> Content? {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = Self.lastLoadDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today),
           let cached = Self.cachedContent {
            return cached
        }
        
        return nil
    }
}

// MARK: - Hashable 구현
extension AIMonthlySummaryCellViewModel: Hashable {
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    nonisolated static func == (lhs: AIMonthlySummaryCellViewModel, rhs: AIMonthlySummaryCellViewModel) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

// MARK: - 월간 요약 로딩 로직
extension AIMonthlySummaryCellViewModel {
    
    /// 월간 요약을 로딩합니다 (HealthDataViewModel 재사용)
    @MainActor
    func loadMonthlySummary() async {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 이미 오늘 로딩했다면 캐시된 데이터 사용
        if let lastDate = Self.lastLoadDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today),
           let cached = Self.cachedContent {
            
            setState(.loaded(cached))
            return
        }
        
        // 1. 로딩 상태로 변경
        setState(.loading)
        
        do {
            // 2. HealthDataViewModel의 getMonthlyHealthData()호출
            let monthlyData = await healthDataViewModel.getMonthlyHealthData()
            
            // 3. 사용자 정보 가져오기
            let userInfo = try userService.fetchUserInfo()
            
            // 4. PromptContext 직접 생성
            let context = createPromptContext(userInfo: userInfo, monthlyData: monthlyData)
            
            // 5. 생성된 context로 프롬프트 생성)
            let aiPrompt = try await promptBuilderService.makePrompt(
                message: nil,
                context: context,           // 직접 생성한 context 전달
                option: .monthlySummary
            )

            // 6. alanService로 AI 요청
            let summaryMessage = await alanService.sendQuestion(aiPrompt)
            
            // 7. 응답 확인
            guard let summaryMessage = summaryMessage, !summaryMessage.isEmpty else {
                throw NSError(domain: "AlanServiceError", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "AI 서비스에서 응답을 받을 수 없어요"
                ])
            }
            
            // 8. Content 생성 및 캐시 저장
            let content = Content(message: summaryMessage)
            
            // 캐시에 저장
            Self.lastLoadDate = today
            Self.cachedContent = content
            
            // 성공 상태로 변경
            setState(.loaded(content))
            
        } catch {
            setState(.failed(error))
        }
    }
    
    // MARK: - Private Methods
    
    /// HealthDataViewModel의 데이터로 PromptContext 생성
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
            activeEnergyBurned: monthlyData.monthlyTotalCalories,     // 월간 총 칼로리
        )
        
        return PromptContext(descriptor: descriptor)
    }
    
    /// 최신 목표 걸음수 찾기
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
