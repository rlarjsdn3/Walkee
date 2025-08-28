//
//  PersonalViewModelTest.swift
//  HealthTests
//
//  Created by juks86 on 8/27/25.
//

import XCTest
@testable import Health

@MainActor
final class WeekSummaryCellViewModelTest: XCTestCase {
    
    var sut: WeekSummaryCellViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = WeekSummaryCellViewModel()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testLoadWeeklyData_WhenHealthKitIsUnlinked_ShouldSetStateToDenied() async {
        // given
        UserDefaultsWrapper.shared.healthkitLinked = false
        defer {
            UserDefaultsWrapper.shared.healthkitLinked = true
        }

        // when
        sut.loadWeeklyData()
        await Task.yield()

        // then
        guard case .denied = sut.state else {
            XCTFail("연동 스위치가 꺼져있을 때 state는 .denied여야 합니다. 현재 상태: \(sut.state)")
            return
        }
    }
}
