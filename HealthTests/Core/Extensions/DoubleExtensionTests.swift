//
//  DoubleExtensionTests.swift
//  HealthTests
//
//  Created by 권도현 on 8/27/25.
//

import XCTest
@testable import Health

final class DoubleExtensionTests: XCTestCase {
    
    func testDegreeToRadian_zeroDegree() {
           let degree: Double = 0
           XCTAssertEqual(degree.radian, 0, accuracy: 1e-10)
       }
       
       func testDegreeToRadian_ninetyDegree() {
           let degree: Double = 90
           XCTAssertEqual(degree.radian, .pi / 2, accuracy: 1e-10)
       }
       
       func testDegreeToRadian_oneEightyDegree() {
           let degree: Double = 180
           XCTAssertEqual(degree.radian, .pi, accuracy: 1e-10)
       }
       
       func testDegreeToRadian_threeSixtyDegree() {
           let degree: Double = 360
           XCTAssertEqual(degree.radian, 2 * .pi, accuracy: 1e-10)
       }
       
       func testDegreeToRadian_negativeDegree() {
           let degree: Double = -45
           XCTAssertEqual(degree.radian, -(.pi / 4), accuracy: 1e-10)
       }
}
