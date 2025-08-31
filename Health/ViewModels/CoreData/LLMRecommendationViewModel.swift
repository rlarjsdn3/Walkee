//
//  LLMRecommendationViewModel.swift
//  Health
//
//  Created by juks86 on 8/20/25.
//

import Foundation
import Combine
import CoreData
import Network

/// AI 기반 걷기 코스 추천을 관리하는 ViewModel 클래스
///
/// 이 클래스는 사용자의 개인 정보(나이, 성별, 키, 몸무게, 질병)를 기반으로
/// LLM(Large Language Model)에게 적절한 걷기 난이도를 추천받는 기능을 제공합니다.
/// 네트워크 상태 모니터링과 캐싱을 통해 안정적인 서비스를 제공합니다.
class LLMRecommendationViewModel: ObservableObject {

    @Injected private var promptBuilderService: (any PromptBuilderService)
    @Injected private var userService: (any CoreDataUserService)

    private var alanService = AlanViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var isErrorHandling = false
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "LLMNetworkMonitor")
    private var isNetworkConnected = false
    private var shouldRetryWhenNetworkReturns = false

    @Published var isLoading = false
    @Published var loadingState: WalkingLoadingView.State = .loading
    @Published var recommendedLevels: [String] = []
    @Published var error: Error?

    /// 마지막으로 저장된 사용자 정보의 해시값
    /// 사용자 정보 변경 감지에 사용
    private var lastUserInfoHash: String? {
        get { UserDefaultsWrapper.shared.lastUserInfoHash }
        set { UserDefaultsWrapper.shared.lastUserInfoHash = newValue }
    }

    /// LLMRecommendationViewModel 초기화
    ///
    /// 초기화 시 다음 작업들을 수행합니다:
    /// - 캐시된 추천 데이터 로드
    /// - 현재 사용자 정보 해시 저장
    /// - 네트워크 상태 모니터링 시작
    init() {
        loadCachedRecommendations()
        saveCurrentUserInfoHash()
        startNetworkMonitoring()
    }

    /// 메모리 해제 시 정리 작업
    ///
    /// 네트워크 모니터와 노티피케이션 센터 구독을 정리합니다.
    deinit {
        networkMonitor.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    /// 네트워크 상태 모니터링을 시작합니다.
    ///
    /// ## 동작 방식
    /// 1. 네트워크 상태 변화를 실시간으로 감지
    /// 2. 연결이 복구되면 대기 중이던 요청을 자동으로 재시도
    ///
    /// 백그라운드 큐에서 네트워크 상태를 모니터링하고,
    /// UI 업데이트는 메인 스레드에서 수행합니다.
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasConnected = self?.isNetworkConnected ?? false  // 이전 연결 상태 저장
                let isNowConnected = (path.status == .satisfied)      // 현재 연결 상태 확인

                self?.isNetworkConnected = isNowConnected

                // 네트워크가 복구된 경우
                if !wasConnected && isNowConnected {

                    // 네트워크 에러로 인해 대기 중이었다면 자동으로 다시 시도
                    if self?.shouldRetryWhenNetworkReturns == true {
                        self?.shouldRetryWhenNetworkReturns = false  // 플래그 리셋
                        await self?.fetchRecommendations()  // 추천 데이터 다시 가져오기
                    }
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }

    /// 추천 데이터 캐시를 삭제합니다.
    ///
    /// UserDefaults와 메모리에 저장된 추천 데이터를 모두 제거합니다.
    /// 사용자 정보가 변경되었을 때 호출하여 새로운 추천을 받도록 합니다
    func clearRecommendationCache() {
        // UserDefaults에서 추천 데이터 삭제
        UserDefaultsWrapper.shared.remove(forKey: \.llmRecommendedCourseLevels)

        // 메모리에서도 삭제
        recommendedLevels = []
    }

    /// 사용자 정보 변경 여부를 확인하고 필요시에만 새로운 추천을 가져옵니다
    func checkAndUpdateIfNeeded() async {
        // 기존 추천이 없으면 항상 fetch
        guard hasValidRecommendations() else {
            await fetchRecommendations()
            return
        }

        // 사용자 정보 변경 체크
        if hasUserInfoChanged() {
            clearRecommendationCache()
            await fetchRecommendations()
            saveCurrentUserInfoHash()
        }
    }

    /// 사용자 정보 변경 여부를 확인합니다.
    ///
    /// - Returns: 사용자 정보가 변경되었으면 `true`, 변경되지 않았으면 `false`
    ///
    /// 현재 사용자 정보의 해시값과 마지막으로 저장된 해시값을 비교하여
    /// 정보 변경 여부를 빠르게 판단합니다.
    private func hasUserInfoChanged() -> Bool {
        let currentHash = getCurrentUserInfoHash()
        return lastUserInfoHash != currentHash
    }

    /// 현재 사용자 정보의 해시값을 생성합니다.
    ///
    /// - Returns: 사용자 정보를 요약한 해시 문자열
    ///
    /// ## 해시에 포함되는 정보
    /// - 나이, 성별, 키, 몸무게
    /// - 질병 개수 (질병 내용이 변경되면 개수도 변경됨)
    ///
    /// 간단한 문자열 조합으로 해시를 생성하여 변경 감지 성능을 최적화합니다.
    private func getCurrentUserInfoHash() -> String {
        do {
            let user = try userService.fetchUserInfo()
            let hash = "\(user.age)-\(user.gender ?? "")-\(user.height)-\(user.weight)-\(user.diseases?.count ?? 0)"
            return hash
        } catch {
            return "error"
        }
    }

    /// 현재 사용자 정보의 해시값을 저장합니다.
    ///
    /// 추천을 받아온 시점의 사용자 정보를 기록하여
    /// 다음에 정보 변경 여부를 확인할 때 비교 기준으로 사용합니다.
    private func saveCurrentUserInfoHash() {
        lastUserInfoHash = getCurrentUserInfoHash()
    }


    /// 저장된 추천 데이터가 있는지 확인합니다.
    func hasValidRecommendations() -> Bool {
        return !recommendedLevels.isEmpty
    }

    /// LLM에서 새로운 추천 받아옵니다.
    @MainActor
    func fetchRecommendations() async {

        // 이미 로딩 중이면 중복 실행 방지
        guard !isLoading else {
            return
        }

        // 로딩 상태 시작
        isLoading = true
        error = nil
        loadingState = .loading

        do {
            // 사용자 정보 가져오기
            let userInfo = try userService.fetchUserInfo()
            print("=== 사용자 정보 ===")
            print("나이: \(userInfo.age)")
            print("성별: \(userInfo.gender ?? "미설정")")
            print("몸무게: \(userInfo.weight)")
            print("키: \(userInfo.height)")

            // Disease 배열을 문자열로 변환
            if let diseases = userInfo.diseases, !diseases.isEmpty {
                let diseaseNames = diseases.map { $0.rawValue }.joined(separator: ", ")
                print("질병: \(diseaseNames)")
            } else {
                print("질병: 없음")
            }

            print("==================")

            // 걷기 추천을 위한 컨텍스트 생성
            let context = createWalkingRecommendationContext(userInfo: userInfo)

            // 프롬프트 생성 (LLM에 보낼 질문 만들기)
            let prompt = try await promptBuilderService.makePrompt(
                message: nil,
                context: context,
                option: .userLevel
            )

            let response = await sendQuestionWithRetry(prompt)

            // 응답이 비어있는지 확인
            guard let response = response, !response.isEmpty else {
                print("응답 비어있음")
                throw LLMRecommendationError.emptyResponse
            }

            // LLM 응답을 파싱해서 레벨 정보 추출
            let levels = parseLLMResponse(response)
            print("추천 받은 난이도: \(levels)")

            // 추천 레벨 저장
            recommendedLevels = levels

            // 추천 결과를 저장소에 저장
            saveRecommendations(levels)

            // 로딩 완료
            isLoading = false

        } catch {
            await handleError(error)
        }
    }

    /// AI 서비스에 질문을 전송하고 실패 시 재시도합니다.
    ///
    /// - Parameter prompt: LLM에게 보낼 프롬프트 문자열
    /// - Returns: AI의 응답 문자열 또는 `nil` (실패한 경우)
    ///
    /// ## 재시도 전략
    /// 1. 첫 번째 시도: 일반적인 질문 전송
    /// 2. 실패 시: 에이전트 상태 초기화 후 재시도
    /// 3. 두 번째도 실패 시: `nil` 반환
    ///
    private func sendQuestionWithRetry(_ prompt: String) async -> String? {

        // 첫 번째 시도
        let firstResponse = await alanService.sendQuestion(prompt)

        // 첫 번째 시도가 성공했으면 결과 반환
        if let response = firstResponse, !response.isEmpty {

            return response
        }

        // 첫 번째 시도 실패 - 에이전트 초기화 후 재시도
        await alanService.resetAgentState()

        let secondResponse = await alanService.sendQuestion(prompt)

        if let response = secondResponse, !response.isEmpty {
            return response
        } else {
            return nil
        }
    }

    /// 캐시된 추천 데이터 로드
    private func loadCachedRecommendations() {
        if let savedLevels = UserDefaultsWrapper.shared.llmRecommendedCourseLevels {
            recommendedLevels = savedLevels
        }
    }

    /// 추천 결과 저장
    private func saveRecommendations(_ levels: [String]) {
        UserDefaultsWrapper.shared.llmRecommendedCourseLevels = levels
    }

    /// 걷기 추천을 위한 프롬프트 컨텍스트를 생성합니다.
    ///
    /// - Parameter userInfo: Core Data에서 가져온 사용자 정보
    /// - Returns: LLM 프롬프트 생성에 사용할 컨텍스트 객체
    ///
    /// 사용자의 개인 정보를 `PromptDescriptor` 형태로 변환하여
    /// AI가 개인화된 추천을 할 수 있도록 합니다.
    private func createWalkingRecommendationContext(userInfo: UserInfoEntity) -> PromptContext {
        let descriptor = PromptDescriptor(
            age: Int(userInfo.age),
            gender: userInfo.gender ?? "unspecified",
            weight: userInfo.weight,
            height: userInfo.height,
            diseases: userInfo.diseases,
            goalStepCount: 0,
            stepCount: 0,
            distanceWalkingRunning: 0,
            activeEnergyBurned: 0
        )

        return PromptContext(descriptor: descriptor)
    }

    /// LLM 응답에서 추천 레벨을 파싱합니다.
    ///
    /// - Parameter response: AI로부터 받은 응답 문자열
    /// - Returns: 추출된 레벨 배열 (1, 2, 3 중 하나 이상)
    func parseLLMResponse(_ response: String) -> [String] {
        let pattern = "[1-3]"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: response, range: NSRange(response.startIndex..., in: response))

        let levels = matches?.compactMap { match in
            String(response[Range(match.range, in: response)!])
        } ?? []

        let result = levels.isEmpty ? ["1"] : Array(Set(levels)).sorted()

        return result
    }

    /// 에러 처리
    @MainActor
    private func handleError(_ error: Error) async {
        self.error = error
        isErrorHandling = true

        // 네트워크 상태에 따라 에러 타입 결정
        if !isNetworkConnected {

            //네트워크가 끊어진 상태 - 모든 에러를 네트워크 에러로 처리
            loadingState = .networkError
            shouldRetryWhenNetworkReturns = true  // 네트워크 복구 시 자동 재시도 플래그 설정

        } else if error is URLError || error is NetworkError {

            // 네트워크 관련 에러
            loadingState = .networkError
            shouldRetryWhenNetworkReturns = true  // 일시적 네트워크 문제일 수 있으므로 재시도


        } else {
            //API 호출 실패, 파싱 에러 등 - 네트워크와 무관한 에러
            loadingState = .failed
            shouldRetryWhenNetworkReturns = false  // 네트워크 복구와 무관하므로 재시도하지 않음
        }

        // 2초간 에러 화면 표시
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        if recommendedLevels.isEmpty {
            recommendedLevels = ["1"]
        }

        // 로딩 완료
        isLoading = false
        isErrorHandling = false
    }
}

/// LLM 추천 과정에서 발생할 수 있는 에러 타입들
enum LLMRecommendationError: Error, LocalizedError {
    case emptyResponse
    case invalidResponse
    case userInfoNotFound

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "AI에서 응답을 받지 못했습니다"
        case .invalidResponse:
            return "AI 응답을 해석할 수 없습니다"
        case .userInfoNotFound:
            return "사용자 정보를 찾을 수 없습니다"
        }
    }
}
