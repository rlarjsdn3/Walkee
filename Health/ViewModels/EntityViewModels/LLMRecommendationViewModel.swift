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

    private var lastUserInfoHash: String? {
        get { UserDefaultsWrapper.shared.lastUserInfoHash }
        set { UserDefaultsWrapper.shared.lastUserInfoHash = newValue }
    }

    init() {
        loadCachedRecommendations()
        saveCurrentUserInfoHash()
        startNetworkMonitoring()
    }

    deinit {
        networkMonitor.cancel()
        NotificationCenter.default.removeObserver(self)
    }

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

                //  네트워크가 끊어진 경우
                if wasConnected && !isNowConnected {
                    print("네트워크가 끊어졌습니다.")
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }

    /// 추천 캐시 삭제
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

    // MARK: - 간단한 변경 감지

    private func hasUserInfoChanged() -> Bool {
        let currentHash = getCurrentUserInfoHash()
        return lastUserInfoHash != currentHash
    }

    private func getCurrentUserInfoHash() -> String {
        do {
            let user = try userService.fetchUserInfo()
            let hash = "\(user.age)-\(user.gender ?? "")-\(user.height)-\(user.weight)-\(user.diseases?.count ?? 0)"
            print("현재 해시 생성: \(hash)")
            return hash
        } catch {
            print("해시 생성 에러: \(error)")
            return "error"
        }
    }

    private func saveCurrentUserInfoHash() {
        lastUserInfoHash = getCurrentUserInfoHash()
    }

    // MARK: - Public Methods

    /// 저장된 추천 데이터가 있는지 확인
    func hasValidRecommendations() -> Bool {
        return !recommendedLevels.isEmpty
    }

    /// LLM에서 새로운 추천 받아오기
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
            // 생성된 프롬프트 출력
            print("=== 보내는 프롬프트 ===")
            print(prompt)
            print("====================")

            let response = await sendQuestionWithRetry(prompt)
            print("응답: \(response ?? "nil")")

            // 받은 응답 출력
            print("=== 받은 응답 ===")
            print("응답: \(response ?? "nil")")
            print("===============")

            // 응답이 비어있는지 확인
            guard let response = response, !response.isEmpty else {
                print("응답 비어있음")
                throw LLMRecommendationError.emptyResponse
            }

            // LLM 응답을 파싱해서 레벨 정보 추출
            let levels = parseLLMResponse(response)

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

    // 에러 발생시 재시도 로직
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
            print("캐시 로드됨: \(savedLevels)")
        }
    }

    // 추천 결과 저장
    private func saveRecommendations(_ levels: [String]) {
        UserDefaultsWrapper.shared.llmRecommendedCourseLevels = levels
    }

    /// 걷기 추천을 위한 프롬프트 컨텍스트 생성
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

    /// LLM 응답 파싱
   func parseLLMResponse(_ response: String) -> [String] {
        let pattern = "[1-3]"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: response, range: NSRange(response.startIndex..., in: response))

        let levels = matches?.compactMap { match in
            String(response[Range(match.range, in: response)!])
        } ?? []

        let result = levels.isEmpty ? ["1"] : Array(Set(levels)).sorted()
        print("파싱 완료 - 결과: \(result)")

        return result
    }

    /// 에러 처리
    @MainActor
    private func handleError(_ error: Error) async {
        self.error = error
        isErrorHandling = true

        print("=== 에러 정보 ===")
        print("에러 타입: \(type(of: error))")
        print("에러 설명: \(error.localizedDescription)")
        print("현재 네트워크 상태: \(isNetworkConnected ? "연결됨" : "연결 안됨")")
        print("===============")

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

// MARK: - Error Types
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
