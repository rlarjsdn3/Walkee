//
//  LLMRecommendationViewModel.swift
//  Health
//
//  Created by juks86 on 8/20/25.
//

import Foundation
import Combine
import CoreData

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
        loadCachedRecommendations()
        setupCoreDataObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - CoreData 변경 감지

    // CoreData 변경사항을 감지하는 옵저버 설정
    private func setupCoreDataObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }

    // CoreData 저장이 완료되었을 때 호출되는 메서드
    @objc private func managedObjectContextDidSave(_ notification: Notification) {

        // UserInfoEntity가 업데이트되었는지 확인
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            let hasUserInfoUpdate = updatedObjects.contains { object in
                return object is UserInfoEntity
            }

            if hasUserInfoUpdate {

                DispatchQueue.main.async { [weak self] in
                    self?.handleUserInfoUpdate()
                }
            }
        }

        // 새로 생성된 UserInfoEntity확인 (처음 앱 설치한 경우)
        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            let hasUserInfoInsert = insertedObjects.contains { object in
                return object is UserInfoEntity
            }

            if hasUserInfoInsert {

                DispatchQueue.main.async { [weak self] in
                    self?.handleUserInfoUpdate()
                }
            }
        }
    }

    /// 사용자 정보가 업데이트되었을 때의 처리
    private func handleUserInfoUpdate() {
        // 기존 추천이 있는 경우에만 새로고침 (첫 로딩은 제외)
        if hasValidRecommendations() {

            clearRecommendationCache()
            Task {
                await fetchRecommendations()
            }
        }
    }

    /// 추천 캐시 삭제
    func clearRecommendationCache() {
        // UserDefaults에서 추천 데이터 삭제
        UserDefaultsWrapper.shared.remove(forKey: \.llmRecommendedCourseLevels)

        // 메모리에서도 삭제
        recommendedLevels = []
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

        do {
            // 사용자 정보 가져오기
            let userInfo = try userService.fetchUserInfo()

            // 걷기 추천을 위한 컨텍스트 생성
            let context = createWalkingRecommendationContext(userInfo: userInfo)

            // 프롬프트 생성 (LLM에 보낼 질문 만들기)
            let prompt = try await promptBuilderService.makePrompt(
                message: nil,
                context: context,
                option: .userLevel
            )

            let response = await sendQuestionWithRetry(prompt)
            print("응답: \(response ?? "nil")")

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
        } else {
            print("캐시 없음")
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
    private func parseLLMResponse(_ response: String) -> [String] {
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

        // 에러 타입에 따른 로딩 상태 설정
        if error is URLError {
            loadingState = .networkError
        } else {
            loadingState = .failed
        }

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
