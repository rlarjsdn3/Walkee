//
//  ArrayExtensionTests.swift
//  HealthTests
//
//  Created by 권도현 on 8/27/25.
//

import XCTest
@testable import Health

final class ArrayExtensionTests: XCTestCase {
    
    func testArryExtension_WhenIndexingOutofBounds_ThenReturnNil() {
        
        //배열 선언
        let array = [1, 2, 3, 4, 5]
        
        // 인덱스의 요소가 유효하지않을때, nil을 리턴
        let num = array[safe: -10]
        
        XCTAssertNil(num)
    }
    
    func testArryExtension_WhenIndexingOutofBounds_ThenReturnElement() {
        
        //배열 선언
        let array = [1, 2, 3, 4, 5]
        
        // 인덱스의 요소가 유효할때, 유효한값 리턴
        let num = array[safe: 2]
        
        XCTAssertEqual(num, 3)
    }
}
