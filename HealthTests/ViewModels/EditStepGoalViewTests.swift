//
//  EditStepGoalViewTests.swift
//  HealthTests
//
//  Created by 하재준 on 8/28/25.
//

import XCTest
@testable import Health

final class EditStepGoalViewTests: XCTestCase {
    let sut = EditStepGoalView()
    
    private func allSubviews(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + allSubviews(of: $0) }
    }
    
    func testPlusButtonIncrease500() {
        sut.setupHierarchy()
        sut.setupAttribute()
        sut.setupConstraints()
        sut.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        sut.layoutIfNeeded()
        sut.configure(defaultValue: 500, step: 500, min: 500, max: 10_000)

        let buttons = allSubviews(of: sut).compactMap { $0 as? UIButton }
        let sorted = buttons.sorted { $0.frame.minX < $1.frame.minX }
        let plus  = sorted[1]
        
        plus.sendActions(for: .touchUpInside)
        XCTAssertEqual(sut.value, 1000)
    }
    
    func testMinusButtonDecrease500() {
        sut.setupHierarchy()
        sut.setupAttribute()
        sut.setupConstraints()
        sut.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        sut.layoutIfNeeded()
        sut.configure(defaultValue: 1500, step: 500, min: 500, max: 10_000)

        let buttons = allSubviews(of: sut).compactMap { $0 as? UIButton }
        let sorted = buttons.sorted { $0.frame.minX < $1.frame.minX }
        let minus = sorted[0]
        
        minus.sendActions(for: .touchUpInside)
        XCTAssertEqual(sut.value, 1000)
    }
}
