//
//  AppenderTests.swift
//  ShipBookTests
//
//  Created by Elisha Sterngold on 08/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import XCTest
@testable import ShipBookSDK

class AppenderTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
    let dirURL = dir!.appendingPathComponent("shipbook")
    try? FileManager.default.createDirectory(atPath: dirURL.path, withIntermediateDirectories: true, attributes: nil)
  }
  
  override func tearDown() {
    SessionManager.shared.pausedUntil = .distantPast
    SessionManager.shared.backOffUntil = .distantPast
    SessionManager.shared.appId = nil
    SessionManager.shared.appKey = nil
    SessionManager.shared.token = nil
    super.tearDown()
  }
  
  func testPatternLayout() {
    var  config  =  Config()
    config["pattern"] = "$time $severityIcon $severity $tag $message [$file:$line] $isMainThread $queueLabel $threadId"
    let consoleAppender = ConsoleAppender(name: "console", config: config)
    let msg = "this is a test"
    let line = #line
    let severity = Severity.Debug
    let tag = "Tag"
    let message = Message(message: msg, severity:severity, tag: tag, function: #function, file: #file, line: line)
    let result = consoleAppender.toString(message: message)
    print(result)
    let expected = "\( message.time.toTimeFormat()) \(consoleAppender.color(severity: severity)) \( severity.name ) \(tag) \(msg) [\(#file):\(line)] true com.apple.main-thread \(Thread.threadId)"
    XCTAssertTrue(result.range(of: expected) != nil)
    
  }
  
  func testCloudAppender() {
    let cloudAppender = SBCloudAppender(name: "cloud", config: nil)
    try? FileManager.default.removeItem(at: cloudAppender.fileURL)
    let token = "testing"
    SessionManager.shared.token = token
    var logs1 = [BaseLog]()
    logs1.append(Message(message: "message1", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs1.append(Message(message: "message2", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs1.append(Message(message: "message3", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs1.append(Message(message: "message4", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs1.append(Message(message: "message5", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs1.append(Exception(name: "test"))
    
    for log in logs1 {
      cloudAppender.saveToFile(data: log)
    }
    
    cloudAppender.hasLog = false //doing like that it starts a new load
    SessionManager.shared.token = nil
    SessionManager.shared.login = Login(appId:"59f196837211df173c430c51", appKey:"5a4b2e7f82416460bd2afc1cdb002e743ac25ce9")
    var logs2 = [BaseLog]()
    logs2.append(Message(message: "message1", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs2.append(Message(message: "message2", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs2.append(Message(message: "message3", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs2.append(Message(message: "message4", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs2.append(Message(message: "message5", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs2.append(Message(message: "message6 \nnew line", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    logs2.append(Exception(name: "test"))
    
    for log in logs2 {
      cloudAppender.saveToFile(data: log)
    }

    var sessionsData: [SessionLogData]? = nil
    XCTAssertNoThrow (sessionsData = try cloudAppender.loadFromFile(url: cloudAppender.fileURL))
    XCTAssertEqual(sessionsData!.count, 2)
    var sessionLogData1 = sessionsData![0]
    XCTAssertNil(sessionLogData1.login)
    XCTAssertEqual(sessionLogData1.token, token)
    XCTAssertEqual(sessionLogData1.logs, logs1)
    var sessionLogData2 = sessionsData![1]
    XCTAssertNil(sessionLogData2.token)
    XCTAssertEqual(sessionLogData2.login, SessionManager.shared.login)
    XCTAssertEqual(sessionLogData2.logs, logs2)
    
    // checking the usage of temp file works
    try! FileManager.default.moveItem(at: cloudAppender.fileURL, to: cloudAppender.tempFileURL)
    let log = Message(message: "message6", severity: .Info, tag: "test", function: #function, file: #file, line: #line)
    cloudAppender.saveToFile(data: log)
    logs2.append(log)
    
    cloudAppender.concatTmpFile()
    sessionsData = nil
    XCTAssertNoThrow (sessionsData = try cloudAppender.loadFromFile(url: cloudAppender.fileURL))
    XCTAssertEqual(sessionsData!.count, 2)
    sessionLogData1 = sessionsData![0]
    XCTAssertNil(sessionLogData1.login)
    XCTAssertEqual(sessionLogData1.token, token)
    XCTAssertEqual(sessionLogData1.logs, logs1)
    sessionLogData2 = sessionsData![1]
    XCTAssertNil(sessionLogData2.token)
    XCTAssertEqual(sessionLogData2.login, SessionManager.shared.login)
    XCTAssertEqual(sessionLogData2.logs, logs2)
  }

  func testCloudAppenderDropsLogsWhilePaused() {
    let cloudAppender = SBCloudAppender(name: "cloud", config: ["maxTime": 3600, "flushSeverity": "Warning"])
    try? FileManager.default.removeItem(at: cloudAppender.fileURL)
    try? FileManager.default.removeItem(at: cloudAppender.crashFile)
    SessionManager.shared.token = nil
    SessionManager.shared.login = Login(appId:"59f196837211df173c430c51", appKey:"5a4b2e7f82416460bd2afc1cdb002e743ac25ce9")

    SessionManager.shared.pausedUntil = Date().addingTimeInterval(600)
    cloudAppender.push(log: Message(message: "kept in memory if not dropped", severity: .Info, tag: "test", function: #function, file: #file, line: #line))
    cloudAppender.push(log: ScreenEvent(name: "paused screen"))
    cloudAppender.push(log: Message(message: "flushed if not dropped", severity: .Error, tag: "test", function: #function, file: #file, line: #line))
    cloudAppender.push(log: Exception(name: "paused exception"))
    DispatchQueue.shipBook.sync {
      cloudAppender.saveToFile(data: Message(message: "saved if not dropped", severity: .Error, tag: "test", function: #function, file: #file, line: #line))
    }
    cloudAppender.saveCrash(exception: Exception(name: "paused crash"))

    XCTAssertFalse(FileManager.default.fileExists(atPath: cloudAppender.fileURL.path))
    XCTAssertFalse(FileManager.default.fileExists(atPath: cloudAppender.crashFile.path))

    SessionManager.shared.pausedUntil = Date()
    let message = Message(message: "after the pause", severity: .Error, tag: "test", function: #function, file: #file, line: #line)
    cloudAppender.push(log: message)
    DispatchQueue.shipBook.sync {}

    var sessionsData: [SessionLogData]? = nil
    XCTAssertNoThrow (sessionsData = try cloudAppender.loadFromFile(url: cloudAppender.fileURL))
    XCTAssertEqual(sessionsData!.count, 1)
    XCTAssertEqual(sessionsData![0].login, SessionManager.shared.login)
    XCTAssertEqual(sessionsData![0].logs, [message])
    try? FileManager.default.removeItem(at: cloudAppender.fileURL)
  }

  func testCloudAppenderKeepsLogsAndCrashesWhileBackingOff() {
    StubURLProtocol.install()
    defer { StubURLProtocol.uninstall() }
    let cloudAppender = SBCloudAppender(name: "cloud", config: ["maxTime": 3600])
    try? FileManager.default.removeItem(at: cloudAppender.fileURL)
    try? FileManager.default.removeItem(at: cloudAppender.crashFile)
    SessionManager.shared.token = "token"

    SessionManager.shared.backOffUntil = Date().addingTimeInterval(600)
    let message = Message(message: "while backing off", severity: .Error, tag: "test", function: #function, file: #file, line: #line)
    cloudAppender.push(log: message)
    cloudAppender.saveCrash(exception: Exception(name: "crash while backing off"))
    DispatchQueue.shipBook.sync { cloudAppender.flush() }

    assertNoRequest()
    var sessionsData: [SessionLogData]? = nil
    XCTAssertNoThrow (sessionsData = try cloudAppender.loadFromFile(url: cloudAppender.fileURL))
    XCTAssertEqual(sessionsData!.count, 1)
    XCTAssertEqual(sessionsData![0].token, "token")
    XCTAssertEqual(sessionsData![0].logs, [message])
    XCTAssertNoThrow (sessionsData = try cloudAppender.loadFromFile(url: cloudAppender.crashFile))
    XCTAssertEqual(sessionsData!.count, 1)
    XCTAssertEqual((sessionsData![0].logs[0] as? Exception)?.name, "crash while backing off")
    try? FileManager.default.removeItem(at: cloudAppender.fileURL)
    try? FileManager.default.removeItem(at: cloudAppender.crashFile)
  }

  func testUploadAnsweredBusyOrRefusedKeepsTheBatch() {
    StubURLProtocol.install()
    defer { StubURLProtocol.uninstall() }
    let cloudAppender = SBCloudAppender(name: "cloud", config: ["maxTime": 3600])
    let answers: [(status: Int, headers: [String: String])] = [
      (429, [:]),
      (429, ["Retry-After": "60"]),
      (503, [:]),
      (429, ["x-shipbook-pause": "600", "Retry-After": "600"]),
      (401, ["x-shipbook-pause": "600", "Retry-After": "600"]),
    ]
    for (status, headers) in answers {
      SessionManager.shared.pausedUntil = .distantPast
      SessionManager.shared.backOffUntil = .distantPast
      SessionManager.shared.token = "token"
      try? FileManager.default.removeItem(at: cloudAppender.fileURL)
      try? FileManager.default.removeItem(at: cloudAppender.tempFileURL)
      cloudAppender.hasLog = false
      let message = Message(message: "sent when the server answered \(status)", severity: .Error, tag: "test", function: #function, file: #file, line: #line)
      DispatchQueue.shipBook.sync { cloudAppender.saveToFile(data: message) }
      StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: status, headers: headers) }
      let uploadsBefore = StubURLProtocol.requests.count

      DispatchQueue.shipBook.sync { cloudAppender.flush() }

      XCTAssertTrue(waitUntil {
        StubURLProtocol.requests.count == uploadsBefore + 1 && FileManager.default.fileExists(atPath: cloudAppender.fileURL.path)
      }, "\(status) \(headers)")
      DispatchQueue.shipBook.sync {}
      var sessionsData: [SessionLogData]? = nil
      XCTAssertNoThrow (sessionsData = try cloudAppender.loadFromFile(url: cloudAppender.fileURL), "\(status) \(headers)")
      XCTAssertEqual(sessionsData?.count, 1, "\(status) \(headers)")
      XCTAssertEqual(sessionsData?.first?.token, "token", "\(status) \(headers)")
      XCTAssertEqual(sessionsData?.first?.logs, [message], "\(status) \(headers)")
      XCTAssertFalse(FileManager.default.fileExists(atPath: cloudAppender.tempFileURL.path), "\(status) \(headers)")
      XCTAssertEqual(StubURLProtocol.requests.count, uploadsBefore + 1, "\(status) \(headers)")
    }
    try? FileManager.default.removeItem(at: cloudAppender.fileURL)
  }

  func testUploadWhoseTokenRefreshIsAnsweredBusyKeepsTheBatch() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "the token is only refreshed on a reachable network")
    StubURLProtocol.install()
    defer { StubURLProtocol.uninstall() }
    let cloudAppender = SBCloudAppender(name: "cloud", config: ["maxTime": 3600])
    try? FileManager.default.removeItem(at: cloudAppender.fileURL)
    try? FileManager.default.removeItem(at: cloudAppender.tempFileURL)
    SessionManager.shared.appKey = "key-1"
    SessionManager.shared.token = "token"
    let message = Message(message: "sent with an expired token", severity: .Error, tag: "test", function: #function, file: #file, line: #line)
    DispatchQueue.shipBook.sync { cloudAppender.saveToFile(data: message) }
    StubURLProtocol.respond = { request in
      request.url!.lastPathComponent == "refreshSdkToken"
        ? StubURLProtocol.Response(status: 503, headers: ["Retry-After": "600"])
        : StubURLProtocol.Response(status: 401, body: Data(#"{"name":"TokenExpired","message":"expired"}"#.utf8))
    }

    DispatchQueue.shipBook.sync { cloudAppender.flush() }

    XCTAssertTrue(waitUntil {
      StubURLProtocol.requests.count == 2 && FileManager.default.fileExists(atPath: cloudAppender.fileURL.path)
    })
    DispatchQueue.shipBook.sync {}
    XCTAssertEqual(StubURLProtocol.requests.map { $0.url!.lastPathComponent }, ["uploadSavedData", "refreshSdkToken"])
    var sessionsData: [SessionLogData]? = nil
    XCTAssertNoThrow (sessionsData = try cloudAppender.loadFromFile(url: cloudAppender.fileURL))
    XCTAssertEqual(sessionsData?.count, 1)
    XCTAssertEqual(sessionsData?.first?.logs, [message])
    XCTAssertFalse(FileManager.default.fileExists(atPath: cloudAppender.tempFileURL.path))
    try? FileManager.default.removeItem(at: cloudAppender.fileURL)
  }
}
