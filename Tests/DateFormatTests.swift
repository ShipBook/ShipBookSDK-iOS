//
//  DateFormatTests.swift
//  ShipBookTests
//
//  Created by Elisha Sterngold on 07/07/2026.
//  Copyright © 2026 ShipBook Ltd. All rights reserved.
//

import XCTest
@testable import ShipBookSDK

class DateFormatTests: XCTestCase {

  func testRoundTrip() throws {
    let date = Date()
    let parsed = try date.toISO8601Format().toDate()
    XCTAssertEqual(parsed.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.001)
  }

  func testToISO8601FormatOutput() {
    let date = Date(timeIntervalSince1970: 1751884706.059)
    XCTAssertEqual(date.toISO8601Format(), "2025-07-07T10:38:26.059+0000")
  }

  // files cached on disk by older SDK versions use the +0000 offset form
  func testParsesLegacyOnDiskFormat() throws {
    let date = try "2025-07-07T10:38:26.059+0000".toDate()
    XCTAssertEqual(date.timeIntervalSince1970, 1751884706.059, accuracy: 0.001)
  }

  func testInvalidStringThrows() {
    XCTAssertThrowsError(try "not a date".toDate())
  }

  func testConcurrentAccess() {
    let date = Date(timeIntervalSince1970: 1751884706.059)
    DispatchQueue.concurrentPerform(iterations: 100) { _ in
      XCTAssertEqual(date.toISO8601Format(), "2025-07-07T10:38:26.059+0000")
      XCTAssertNotNil(try? "2025-07-07T10:38:26.059+0000".toDate())
    }
  }
}
