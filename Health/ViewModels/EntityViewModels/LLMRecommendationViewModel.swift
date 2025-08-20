//
//  LLMRecommendationViewModel.swift
//  Health
//
//  Created by juks86 on 8/20/25.
//

import Foundation
import Combine

class LLMRecommendationViewModel: ObservableObject {

    @Injected private var promptBuilderService: (any PromptBuilderService)
    @Injected private var userService: (any CoreDataUserService)

    private var alanService = AlanViewModel()
    private var cancellables = Set<AnyCancellable>()

    @Published var isLoading = false
    @Published var loadingState: WalkingLoadingView.State = .loading
    @Published var recommendedLevels: [String] = []
    @Published var error: Error?

    init() {

    }

    // MARK: - Public Methods

    /// LLM에서 새로운 추천 받아오기
    @MainActor
    func fetchRecommendations() async {

        guard !isLoading else {

            return
        }
        isLoading = true
        error = nil

        do {

            let userInfo = try userService.fetchUserInfo()
            let context = createWalkingRecommendationContext(userInfo: userInfo)
            let prompt = try await promptBuilderService.makePrompt(
                message: nil,
                context: context,
                option: .userLevel
            )

            let response = await alanService.sendQuestion(prompt)


            guard let response = response, !response.isEmpty else {

                throw LLMRecommendationError.emptyResponse
            }

            let levels = parseLLMResponse(response)

            recommendedLevels = levels

            isLoading = false

        } catch {

            await handleError(error)
        }
    }


    /// 걷기 추천을 위한 프롬프트 컨텍스트 생성
    private func createWalkingRecommendationContext(userInfo: UserInfoEntity) -> PromptContext {
        let descriptor = PromptDescriptor(
            age: Int(userInfo.age),
            gender: userInfo.gender ?? "unspecified",
            weight: userInfo.weight,
            height: userInfo.height,
            diseases: userInfo.diseases,
            goalStepCount: 0, // 걷기 난이도에는 불필요
            stepCount: 0,
            distanceWalkingRunning: 0,
            activeEnergyBurned: 0
        )

        return PromptContext(descriptor: descriptor)
    }

    /// LLM 응답 파싱
    private func parseLLMResponse(_ response: String) -> [String] {
        let pattern = "[1-3]"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: response, range: NSRange(response.startIndex..., in: response))

        let levels = matches?.compactMap { match in
            String(response[Range(match.range, in: response)!])
        } ?? []

        let result = levels.isEmpty ? ["1"] : Array(Set(levels)).sorted()
        print("🔍 파싱 완료 - 결과: \(result)")

        return result
    }

    /// 에러 처리
    @MainActor
    private func handleError(_ error: Error) async {
        self.error = error

        // 에러 타입에 따른 로딩 상태 설정
        if let networkError = error as? URLError {
            loadingState = .networkError
        } else {
            loadingState = .failed
        }

        // 여기서 isLoading을 false로 하지 말고 유지
        // isLoading = false  // 이 줄 제거

        // 2초간 에러 화면 표시
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // 기본값 설정
        if recommendedLevels.isEmpty {
            recommendedLevels = ["1"]
        }

        // 마지막에 로딩 완료 처리
        isLoading = false
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
