//
//  EditHeightViewTests.swift
//  HealthTests
//
//  Created by 하재준 on 8/28/25.
//

import XCTest
@testable import Health

final class EditHeightViewTests: XCTestCase {
    
    let sut = EditHeightView()
    let dummyPicker = UIPickerView()

    
    func testPickerRowsCount() {
        // 100~230 개수 맞는지 테스트
        let rowCount = sut.pickerView(dummyPicker, numberOfRowsInComponent: 0)
        XCTAssertEqual(rowCount, 131)
    }
}
