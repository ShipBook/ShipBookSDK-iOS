//
//  CrashManagerTests.swift
//  ShipBookTests
//
//  Created by Elisha Sterngold on 20/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import XCTest

@testable import ShipBookSDK

class CrashManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
      CrashManager.shared.start()
//      signal(<#T##Int32#>, <#T##((Int32) -> Void)!##((Int32) -> Void)!##(Int32) -> Void#>)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
