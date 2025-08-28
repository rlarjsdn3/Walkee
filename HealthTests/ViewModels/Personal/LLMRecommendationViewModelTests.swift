//
//  LLMRecommendationViewModelTests.swift
//  HealthTests
//
//  Created by juks86 on 8/28/25.
//

import XCTest
@testable import Health

@MainActor
final class LLMRecommendationViewModelTests: XCTestCase {

    var sut: LLMRecommendationViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        UserDefaultsWrapper.shared.llmRecommendedCourseLevels = []
        UserDefaultsWrapper.shared.lastUserInfoHash = ""

        sut = LLMRecommendationViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testParseLLMResponse_WhenGivenStringWithNumbers_ShouldExtractLevelsCorrectly() {
        // given
        let aiResponse = "1과 3의 난이도를 추천합니다."
        let expectedLevels = ["1", "3"]

        // when
        let actualLevels = sut.parseLLMResponse(aiResponse)

        // then
        XCTAssertEqual(actualLevels, expectedLevels, "문자열에서 숫자 '1'과 '3'을 정확히 추출해야 합니다.")
    }

    func testParseLLMResponse_WhenGivenStringWithoutNumbers_ShouldReturnDefaultLevel() {
        // give
        let aiResponse = "오늘의 날씨가 맑네요!"
        let expectedLevels = ["1"]

        // when
        let actualLevels = sut.parseLLMResponse(aiResponse)

        // then
        XCTAssertEqual(actualLevels, expectedLevels, "파싱할 숫자가 없으면 기본값 '1' 을 반환해야 합니다.")
    }

    func testClearRecommendationCache_WhenCalled_ShouldEmptyRecommendedLevels() {
        // given
        sut.recommendedLevels = ["1", "2"]
        XCTAssertFalse(sut.recommendedLevels.isEmpty, "테스트를 위해 초기 데이터가 필요합니다.")

        // when
        sut.clearRecommendationCache()

        // then
        XCTAssertTrue(sut.recommendedLevels.isEmpty, "clearRecommendationCache 호출 후에는 recommendedLevels 배열이 비어있어야 합니다.")
    }

    func testInit_WhenCachedDataExists_ShouldLoadRecommendations() {
        // given
        let cachedLevels = ["2", "3"]
        UserDefaultsWrapper.shared.llmRecommendedCourseLevels = cachedLevels

        // when
        let newViewModel = LLMRecommendationViewModel()

        // then
        XCTAssertEqual(newViewModel.recommendedLevels, cachedLevels, "UserDefaults의  추천 난이도 캐시 데이터를 불러와야 합니다.")
    }
}
