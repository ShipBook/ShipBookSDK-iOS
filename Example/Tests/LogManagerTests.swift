//
//  LogManagerTests.swift
//  ShipBookTests
//
//  Created by Elisha Sterngold on 07/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import XCTest
@testable import ShipBookSDK


class LogManagerTests: XCTestCase {
  
  override func setUp() {
    print("==== Set Up ====")
    super.setUp()
    continueAfterFailure = false
    let configString = """
    {
      "appenders" :
      [{
        "type" : "ConsoleAppender",
        "name" : "console",
        "config": {
          "pattern" : "$time $severity $tag $message /n $file:$line"
        }
       },
       {
        "type" : "SLCloudAppender",
        "name" : "cloud",
        "config": {
          "maxTime" : 5
        }
       }],
      "loggers" :
      [{
       "name" : "iOSExample.SecondViewController",
       "severity" : "Verbose",
       "appenderRef" : "console"
       },
       {
       "name" : "iOSExample.MainViewController",
       "severity" : "Info",
       "appenderRef" : "cloud"
       },
       {
        "severity" : "Error",
        "appenderRef" : "console"
      }]
    }
    """

    var  config : ConfigResponse?
    XCTAssertNoThrow(config = try ConnectionClient.jsonDecoder.decode(ConfigResponse.self, from: configString.data(using: String.Encoding.utf8)!))
    let exp = expectation(description: "\(#function)\(#line)")
    
    LogManager.shared.config(config!)
    DispatchQueue.shipBook.async {
      exp.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  override func tearDown() {
    LogManager.shared.clear()
    super.tearDown()
    print("==== Tear Down ====")
  }
  
  func testAppenders() {
    let appenders = LogManager.shared.appenders
    //check appenders
    XCTAssertTrue(appenders["console"] is ConsoleAppender)
    let consoleAppender = appenders["console"] as? ConsoleAppender
    XCTAssertEqual(consoleAppender?.pattern, "$time $severity $tag $message /n $file:$line")
    XCTAssertTrue(appenders["cloud"] is SBCloudAppender)
    let cloudAppender = appenders["cloud"] as? SBCloudAppender
    XCTAssertEqual(cloudAppender?.maxTime, 5)
  }
  
  func testLogSeverity() {
    var severity = LogManager.shared.getSeverity("example");
    XCTAssertEqual(severity, Severity.Error)
    severity = LogManager.shared.getSeverity("iOSExample.SecondViewController.inner");
    XCTAssertEqual(severity, Severity.Verbose)
    severity = LogManager.shared.getSeverity("iOSExample.MainViewController");
    XCTAssertEqual(severity, Severity.Info)
  }

  typealias PushHandlerType = (BaseLog) -> Void
  class TestAppender : BaseAppender {
    func update(config: Config?) {

    }
    
    var pushHandler : PushHandlerType?
    var name: String
    required init(name: String, config: Config?) {
      self.name = name
    }
    
    convenience init(pushHandler: @escaping PushHandlerType  ) {
      self.init(name: "test", config: nil)
      self.pushHandler = pushHandler
    }
    
    func push(log: BaseLog) {
      pushHandler?(log)
    }
    
    func flush() {
    }
  }

  func testPush() {
    let expect = expectation(description: "check test push")
    let msg = "nice"
    let currentLabel = DispatchQueue.currentLabel
    
    let test = TestAppender() { log in
      let message = log as! Message
      XCTAssertEqual(message.message, msg)
      XCTAssertEqual(message.threadInfo.queueLabel, currentLabel)
      XCTAssertEqual(message.severity, .Error)
      XCTAssertNotNil(message.callStackSymbols)
      expect.fulfill()
    }
    
    LogManager.shared.add(appender: test, name: "test")
    LogManager.shared.add(module: "", severity: .Info, callStackSeverity: .Error, appender: "test")
    let log = Log("test")
    log.d("shouldn't do anything")
    log.e(msg)
    waitForExpectations(timeout: 10, handler: nil)
  }
  
  func testConfigChange() {
    let log = Log("testConfig")
    let expect = expectation(description: "check config change")
    XCTAssertFalse(log.isEnabled(Severity.Warning))
    
    // Set self as an observer
    var token: NSObjectProtocol?
    token = NotificationCenter.default.addObserver(
      forName: NotificationName.ConfigChange,
      object: nil,
      queue: nil) { (notification) in
        NotificationCenter.default.removeObserver(token!)
        XCTAssertTrue(log.isEnabled(Severity.Warning))
        expect.fulfill()

    }
    
    let configString = """
    {
      "appenders" :
      [{
        "type" : "ConsoleAppender",
        "name" : "console",
        "config": {
          "pattern" : "$time $severity $tag $message /n $file:$line"
        }
       }],
      "loggers": [{
        "severity" : "Verbose",
        "appenderRef" : "console"
      }]
    }
    """
    var  config : ConfigResponse?
    XCTAssertNoThrow(config = try ConnectionClient.jsonDecoder.decode(ConfigResponse.self, from: configString.data(using: String.Encoding.utf8)!))
    LogManager.shared.config(config!)

    waitForExpectations(timeout: 1, handler: nil)
  }
}
