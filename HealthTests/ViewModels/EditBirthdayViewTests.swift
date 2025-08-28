//
//  EditBirthdayViewTests.swift
//  HealthTests
//
//  Created by 하재준 on 8/28/25.
//

import XCTest
@testable import Health

final class EditBirthdayViewTests: XCTestCase {
    let sut = EditBirthdayView()
    let dummyPicker = UIPickerView()
    
    func testYearsRangeIs1900ToCurrentYearMinus1() {
        sut.setupAttribute()
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let rowCount = sut.pickerView(dummyPicker, numberOfRowsInComponent: 0)

        // 첫번째 == 1900, 마지막 == 작년
        XCTAssertEqual(sut.pickerView(dummyPicker, titleForRow: 0, forComponent: 0), "1900년")
        XCTAssertEqual(sut.pickerView(dummyPicker, titleForRow: rowCount - 1, forComponent: 0), "\(currentYear - 1)년")
    }
}
