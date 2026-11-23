//
//  EventManagerTests.swift
//  ShipBookTests
//
//  Copyright © 2026 ShipBook Ltd. All rights reserved.
//

#if canImport(UIKit)
import XCTest
import UIKit
@testable import ShipBookSDK

// No test here creates a UIView: without a host app the first one stalls the run for a minute or more.
class EventManagerTests: XCTestCase {
  private let action = #selector(UIResponder.resignFirstResponder)

  func testAnActionWithoutSenderIsNotAUserAction() {
    XCTAssertNil(EventManager.shared.actionEvent(action: action, target: nil, sender: nil))
    XCTAssertNil(EventManager.shared.actionEvent(action: action, target: NSObject(), sender: nil))
  }

  func testTabAndNavigationBarItemsAreRecordedWithTheirTitle() {
    let done = UIBarButtonItem(title: "Done", style: .plain, target: nil, action: nil)
    let home = UITabBarItem(title: "Home", image: nil, tag: 0)

    let doneEvent = EventManager.shared.actionEvent(action: action, target: NSObject(), sender: done)
    XCTAssertEqual(doneEvent?.action, "resignFirstResponder")
    XCTAssertEqual(doneEvent?.sender, "UIBarButtonItem")
    XCTAssertEqual(doneEvent?.senderTitle, "Done")
    XCTAssertEqual(doneEvent?.target, "NSObject")
    XCTAssertEqual(EventManager.shared.actionEvent(action: action, target: nil, sender: home)?.senderTitle, "Home")
  }

  func testASenderWithoutATitleIsRecordedWithoutOne() {
    let event = EventManager.shared.actionEvent(action: action, target: nil, sender: UIGestureRecognizer())

    XCTAssertEqual(event?.sender, "UIGestureRecognizer")
    XCTAssertNil(event?.senderTitle)
    XCTAssertNil(event?.target)
  }
}
#endif
