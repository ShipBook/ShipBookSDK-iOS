import XCTest
@testable import ShipBookSDK

class SessionManagerTests: XCTestCase {
  private static let quietConfig = #"{"appenders":[],"loggers":[],"exceptionReportDisabled":true,"eventLoggingDisabled":true}"#

  private let session = SessionManager.shared
  private let appId = "5f0000000000000000000001"
  private let appKey = "key-1"
  private let sessionUrl = "https://console.shipbook.io/session/1"

  private var loginRequests: [URLRequest] {
    return StubURLProtocol.requests.filter { $0.url?.lastPathComponent == "loginSdk" }
  }

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    StubURLProtocol.install()
    resetSession()
    try? FileManager.default.createDirectory(at: session.dirURL, withIntermediateDirectories: true, attributes: nil)
    try? Data(SessionManagerTests.quietConfig.utf8).write(to: session.configURL)
  }

  override func tearDown() {
    XCTAssertTrue(loginFinished())
    StubURLProtocol.uninstall()
    resetSession()
    try? FileManager.default.removeItem(at: session.configURL)
    DispatchQueue.shipBook.sync {}
    super.tearDown()
  }

  private func resetSession() {
    session.appId = nil
    session.appKey = nil
    session.token = nil
    session.sessionLink = nil
    session.login = nil
    session.loginCompletion = nil
    session.pausedUntil = .distantPast
    session.backOffUntil = .distantPast
    try? FileManager.default.removeItem(at: session.pauseURL)
  }

  private func loginFinished() -> Bool {
    return waitUntil { DispatchQueue.shipBook.sync { !self.session.isInLoginRequest } }
  }

  private func loginSucceeds() -> StubURLProtocol.Response {
    let body = #"{"token":"token-1","sessionUrl":"\#(sessionUrl)","sessionLink":"1:app:session","config":\#(SessionManagerTests.quietConfig)}"#
    return StubURLProtocol.Response(body: Data(body.utf8))
  }

  private func storePause(appId: String, sdkVersion: String, until: Date) throws {
    let record = #"{"appId":"\#(appId)","sdkVersion":"\#(sdkVersion)","until":\#(Int64(until.timeIntervalSince1970 * 1000))}"#
    try Data(record.utf8).write(to: session.pauseURL)
  }

  private func assertStartLogsInAndDeletesTheStoredPause(file: StaticString = #filePath, line: UInt = #line) throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in self.loginSucceeds() }

    ShipBook.start(appId: appId, appKey: appKey)

    XCTAssertFalse(session.paused, file: file, line: line)
    XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path), file: file, line: line)
    XCTAssertTrue(loginFinished(), file: file, line: line)
    XCTAssertEqual(loginRequests.count, 1, file: file, line: line)
    XCTAssertEqual(session.token, "token-1", file: file, line: line)
  }

  func testSessionHeadersCarryTheSessionLink() {
    SessionManager.shared.sessionLink = "1:698ad6e6595b3f6a7590b24f:66f1c2a9e4b0d3f8a1b2c3d4"
    XCTAssertEqual(ShipBook.getSessionHeaders(), ["x-shipbook-session": "1:698ad6e6595b3f6a7590b24f:66f1c2a9e4b0d3f8a1b2c3d4"])
  }

  func testSessionHeadersAreEmptyBeforeLogin() {
    SessionManager.shared.sessionLink = nil
    XCTAssertEqual(ShipBook.getSessionHeaders(), [:])
  }

  func testStartStaysPausedOnAStoredPause() throws {
    let until = Date().addingTimeInterval(600)
    try storePause(appId: appId, sdkVersion: shipBookSDKVersion, until: until)
    var completions = 0

    let log = captureInnerLog {
      ShipBook.start(appId: appId, appKey: appKey) { _ in completions += 1 }
    }

    XCTAssertTrue(session.paused)
    XCTAssertEqual(session.pausedUntil.timeIntervalSince1970, until.timeIntervalSince1970, accuracy: 0.001)
    XCTAssertTrue(log.contains("Warning - paused until \(innerLogTime(session.pausedUntil)) (from an earlier run); nothing will be sent\n"), log)
    XCTAssertNotNil(log.range(of: #"paused until \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z \(from"#, options: .regularExpression), log)
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    assertNoRequest()
    XCTAssertEqual(completions, 0)
    XCTAssertTrue(FileManager.default.fileExists(atPath: session.pauseURL.path))
  }

  func testStartDeletesAPauseStoredForAnotherApp() throws {
    try storePause(appId: "5f0000000000000000000002", sdkVersion: shipBookSDKVersion, until: Date().addingTimeInterval(600))
    try assertStartLogsInAndDeletesTheStoredPause()
  }

  func testStartDeletesAPauseStoredByAnotherSdkVersion() throws {
    try storePause(appId: appId, sdkVersion: "0.0.1", until: Date().addingTimeInterval(600))
    try assertStartLogsInAndDeletesTheStoredPause()
  }

  func testStartDeletesAPauseThatIsOver() throws {
    try storePause(appId: appId, sdkVersion: shipBookSDKVersion, until: Date().addingTimeInterval(-1))
    try assertStartLogsInAndDeletesTheStoredPause()
  }

  func testStartDeletesAPauseMoreThan30DaysAhead() throws {
    try storePause(appId: appId, sdkVersion: shipBookSDKVersion, until: Date().addingTimeInterval(30 * 24 * 60 * 60 + 60))
    try assertStartLogsInAndDeletesTheStoredPause()
  }

  func testStartKeepsAPauseJustUnder30DaysAhead() throws {
    try storePause(appId: appId, sdkVersion: shipBookSDKVersion, until: Date().addingTimeInterval(30 * 24 * 60 * 60 - 60))

    ShipBook.start(appId: appId, appKey: appKey)

    XCTAssertTrue(session.paused)
    XCTAssertTrue(FileManager.default.fileExists(atPath: session.pauseURL.path))
    assertNoRequest()
  }

  func testStartTreatsACorruptPauseFileAsAbsent() throws {
    for corrupt in ["", "not json", "{\"appId\":", "[]", "{\"appId\":\"\(appId)\",\"sdkVersion\":\"\(shipBookSDKVersion)\",\"until\":\"tomorrow\"}"] {
      try Data(corrupt.utf8).write(to: session.pauseURL)
      session.appId = nil

      ShipBook.start(appId: appId, appKey: appKey)

      XCTAssertFalse(session.paused, corrupt)
      XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path), corrupt)
      XCTAssertTrue(loginFinished(), corrupt)
    }
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    XCTAssertEqual(loginRequests.count, 5)
  }

  func testWhilePausedNothingLogsIn() throws {
    try storePause(appId: appId, sdkVersion: shipBookSDKVersion, until: Date().addingTimeInterval(600))
    ShipBook.start(appId: appId, appKey: appKey)

    session.token = "left over"
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    session.token = nil
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    ShipBook.logout()
    ShipBook.start(appId: appId, appKey: appKey)
    ShipBook.start(appId: appId, appKey: "key-2")
    DispatchQueue.shipBook.sync {}
    let refreshed = expectation(description: "refresh")
    session.token = "left over"
    session.refreshToken { succeeded in
      XCTAssertFalse(succeeded)
      refreshed.fulfill()
    }
    wait(for: [refreshed], timeout: 5)

    assertNoRequest()
    XCTAssertTrue(session.paused)
  }

  func testSecondStartDoesNotLogInAgain() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in self.loginSucceeds() }
    let first = expectation(description: "first completion")
    ShipBook.start(appId: appId, appKey: appKey) { url in
      XCTAssertEqual(url, self.sessionUrl)
      first.fulfill()
    }
    wait(for: [first], timeout: 5)
    XCTAssertTrue(loginFinished())

    let second = expectation(description: "second completion")
    ShipBook.start(appId: appId, appKey: appKey) { url in
      XCTAssertEqual(url, self.sessionUrl)
      second.fulfill()
    }
    wait(for: [second], timeout: 5)
    ShipBook.start(appId: appId, appKey: appKey)

    DispatchQueue.shipBook.sync {}
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    XCTAssertEqual(loginRequests.count, 1)
    XCTAssertEqual(loginRequests.first?.value(forHTTPHeaderField: "x-shipbook-app-id"), appId)
    XCTAssertEqual(loginRequests.first?.value(forHTTPHeaderField: "x-shipbook-sdk"), "ios/\(shipBookSDKVersion)")
    XCTAssertEqual(session.token, "token-1")
  }

  func testSecondStartBeforeLoginFinishedKeepsTheNewestCompletion() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in self.loginSucceeds() }
    let gate = DispatchSemaphore(value: 0)
    StubURLProtocol.gate = gate
    var firstCompletions = 0
    let newest = expectation(description: "newest completion")

    ShipBook.start(appId: appId, appKey: appKey) { _ in firstCompletions += 1 }
    ShipBook.start(appId: appId, appKey: appKey) { url in
      XCTAssertEqual(url, self.sessionUrl)
      newest.fulfill()
    }
    DispatchQueue.shipBook.sync {}
    gate.signal()

    wait(for: [newest], timeout: 5)
    XCTAssertTrue(loginFinished())
    XCTAssertEqual(firstCompletions, 0)
    XCTAssertEqual(loginRequests.count, 1)
  }

  func testSecondStartWithoutCompletionKeepsTheEarlierOne() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in self.loginSucceeds() }
    let gate = DispatchSemaphore(value: 0)
    StubURLProtocol.gate = gate
    let earlier = expectation(description: "earlier completion")

    ShipBook.start(appId: appId, appKey: appKey) { url in
      XCTAssertEqual(url, self.sessionUrl)
      earlier.fulfill()
    }
    ShipBook.start(appId: appId, appKey: appKey)
    DispatchQueue.shipBook.sync {}
    gate.signal()

    wait(for: [earlier], timeout: 5)
    XCTAssertTrue(loginFinished())
    XCTAssertEqual(loginRequests.count, 1)
  }

  func testStartWithAnotherAppKeyLogsInAgain() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in self.loginSucceeds() }
    ShipBook.start(appId: appId, appKey: appKey)
    XCTAssertTrue(loginFinished())

    XCTAssertEqual(session.token, "token-1")
    StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: 500) }
    ShipBook.start(appId: appId, appKey: "key-2")
    XCTAssertTrue(loginFinished())

    XCTAssertEqual(loginRequests.count, 2)
    XCTAssertEqual(loginRequests.compactMap { $0.value(forHTTPHeaderField: "Authorization") }, [])
    XCTAssertEqual(session.appKey, "key-2")
    XCTAssertNil(session.token)
    XCTAssertEqual(ShipBook.getSessionHeaders(), [:])
  }

  func testLoginPausedByTheServerLogsInAgainWhenThePauseIsOver() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: 401, headers: ["x-shipbook-pause": "600", "Retry-After": "600"]) }
    var completions = 0
    let log = captureInnerLog {
      ShipBook.start(appId: appId, appKey: appKey) { _ in completions += 1 }
      XCTAssertTrue(loginFinished())
    }

    XCTAssertTrue(session.paused)
    XCTAssertFalse(session.loginFailedPermanently)
    XCTAssertTrue(log.contains("paused until"), log)
    XCTAssertFalse(log.contains("check appId/appKey"), log)
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    ShipBook.start(appId: appId, appKey: appKey) { _ in completions += 1 }
    DispatchQueue.shipBook.sync {}
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    XCTAssertEqual(loginRequests.count, 1)
    XCTAssertEqual(completions, 0)

    StubURLProtocol.respond = { _ in self.loginSucceeds() }
    session.pausedUntil = Date()
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    XCTAssertTrue(loginFinished())

    XCTAssertEqual(loginRequests.count, 2)
    XCTAssertEqual(completions, 1)
    DispatchQueue.shipBook.sync { XCTAssertTrue(session.connected) }
  }

  func testLogin4xxWithoutASignalIsNotRetriedUntilTheNextAppStart() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: 401, headers: ["Retry-After": "600"]) }
    let log = captureInnerLog {
      ShipBook.start(appId: appId, appKey: appKey)
      XCTAssertTrue(loginFinished())
    }

    XCTAssertFalse(session.requestsBlocked)
    XCTAssertTrue(session.loginFailedPermanently)
    XCTAssertTrue(log.contains("loginSdk rejected with 401 — check appId/appKey. Will not retry until next app start."), log)
    XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path))
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    ShipBook.start(appId: appId, appKey: appKey)
    DispatchQueue.shipBook.sync {}
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    XCTAssertEqual(loginRequests.count, 1)
  }

  func testRefreshPausedByTheServerIsNotAPermanentFailure() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { request in
      switch request.url!.lastPathComponent {
      case "loginSdk": return self.loginSucceeds()
      case "refreshSdkToken": return StubURLProtocol.Response(status: 429, headers: ["x-shipbook-pause": "600", "Retry-After": "600"])
      default: return StubURLProtocol.Response(status: 401, body: Data(#"{"name":"TokenExpired","message":"expired"}"#.utf8))
      }
    }
    ShipBook.start(appId: appId, appKey: appKey)
    XCTAssertTrue(loginFinished())

    let uploaded = expectation(description: "upload")
    let log = captureInnerLog {
      ConnectionClient.shared.request(url: "sessions/uploadSavedData", data: String?.none, method: .POST) { response in
        XCTAssertEqual(response.statusCode, 401)
        uploaded.fulfill()
      }
      wait(for: [uploaded], timeout: 5)
    }

    XCTAssertEqual(StubURLProtocol.requests.map { $0.url!.lastPathComponent }, ["loginSdk", "uploadSavedData", "refreshSdkToken"])
    XCTAssertTrue(session.paused)
    XCTAssertNil(session.token)
    XCTAssertFalse(session.loginFailedPermanently)
    XCTAssertFalse(log.contains("check appId/appKey"), log)
  }

  func testRefresh4xxWithoutASignalIsAPermanentFailure() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { request in
      switch request.url!.lastPathComponent {
      case "loginSdk": return self.loginSucceeds()
      case "refreshSdkToken": return StubURLProtocol.Response(status: 401, headers: ["Retry-After": "600"])
      default: return StubURLProtocol.Response(status: 401, body: Data(#"{"name":"TokenExpired","message":"expired"}"#.utf8))
      }
    }
    ShipBook.start(appId: appId, appKey: appKey)
    XCTAssertTrue(loginFinished())

    let uploaded = expectation(description: "upload")
    let log = captureInnerLog {
      ConnectionClient.shared.request(url: "sessions/uploadSavedData", data: String?.none, method: .POST) { _ in uploaded.fulfill() }
      wait(for: [uploaded], timeout: 5)
    }

    XCTAssertFalse(session.requestsBlocked)
    XCTAssertTrue(session.loginFailedPermanently)
    XCTAssertTrue(log.contains("refreshSdkToken rejected with 401 — check appId/appKey. Will not retry until next app start."), log)
  }

  func testLoginAnsweredBusyBacksOffAndLogsInAgainAfterwards() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    for status in [429, 503] {
      session.appId = nil
      session.backOffUntil = .distantPast
      let loginsBefore = loginRequests.count
      StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: status, headers: ["Retry-After": "600"]) }
      var completions = 0
      let log = captureInnerLog {
        ShipBook.start(appId: appId, appKey: appKey) { _ in completions += 1 }
        XCTAssertTrue(loginFinished())
      }

      XCTAssertTrue(log.contains("backing off until"), log)
      XCTAssertFalse(log.contains("check appId/appKey"), log)
      XCTAssertTrue(session.requestsBlocked, "\(status)")
      XCTAssertFalse(session.paused, "\(status)")
      XCTAssertFalse(session.loginFailedPermanently, "\(status)")
      XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path), "\(status)")
      DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
      ShipBook.logout()
      ShipBook.start(appId: appId, appKey: appKey)
      DispatchQueue.shipBook.sync {}
      RunLoop.current.run(until: Date().addingTimeInterval(0.2))
      XCTAssertEqual(loginRequests.count, loginsBefore + 1, "\(status)")

      StubURLProtocol.respond = { _ in self.loginSucceeds() }
      session.backOffUntil = Date()
      DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
      XCTAssertTrue(loginFinished())

      XCTAssertEqual(loginRequests.count, loginsBefore + 2, "\(status)")
      XCTAssertEqual(completions, 1, "\(status)")
      DispatchQueue.shipBook.sync { XCTAssertTrue(session.connected) }
    }
  }

  func testWhileBackingOffNothingLogsInAndTheTokenStays() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in self.loginSucceeds() }
    ShipBook.start(appId: appId, appKey: appKey)
    XCTAssertTrue(loginFinished())
    let loginsBefore = StubURLProtocol.requests.count

    session.backOffUntil = Date().addingTimeInterval(600)
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    let refreshed = expectation(description: "refresh")
    session.refreshToken { succeeded in
      XCTAssertFalse(succeeded)
      refreshed.fulfill()
    }
    wait(for: [refreshed], timeout: 5)
    ShipBook.start(appId: appId, appKey: appKey)
    DispatchQueue.shipBook.sync {}
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))

    XCTAssertEqual(StubURLProtocol.requests.count, loginsBefore)
    XCTAssertEqual(session.token, "token-1")
    XCTAssertEqual(ShipBook.getSessionHeaders(), ["x-shipbook-session": "1:app:session"])

    session.backOffUntil = Date()
    DispatchQueue.shipBook.sync { XCTAssertTrue(session.connected) }
    DispatchQueue.shipBook.sync {}
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    XCTAssertEqual(StubURLProtocol.requests.count, loginsBefore)
    XCTAssertEqual(session.token, "token-1")
  }

  func testStartWithOtherCredentialsHeldBackByABackOffLogsInAfterwards() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in self.loginSucceeds() }
    ShipBook.start(appId: appId, appKey: appKey)
    XCTAssertTrue(loginFinished())

    session.backOffUntil = Date().addingTimeInterval(600)
    ShipBook.start(appId: appId, appKey: "key-2")
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    XCTAssertEqual(loginRequests.count, 1)
    XCTAssertNil(session.token)
    XCTAssertEqual(ShipBook.getSessionHeaders(), [:])

    session.backOffUntil = Date()
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    XCTAssertTrue(loginFinished())

    XCTAssertEqual(loginRequests.count, 2)
    XCTAssertEqual(loginRequests.compactMap { $0.value(forHTTPHeaderField: "Authorization") }, [])
    DispatchQueue.shipBook.sync { XCTAssertTrue(session.connected) }
  }

  func testLogoutHeldBackByABackOffLogsInAfterwards() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { _ in self.loginSucceeds() }
    ShipBook.start(appId: appId, appKey: appKey)
    XCTAssertTrue(loginFinished())

    session.backOffUntil = Date().addingTimeInterval(600)
    ShipBook.logout()
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    XCTAssertEqual(loginRequests.count, 1)

    session.backOffUntil = Date()
    DispatchQueue.shipBook.sync { XCTAssertFalse(session.connected) }
    XCTAssertTrue(loginFinished())

    XCTAssertEqual(loginRequests.count, 2)
    DispatchQueue.shipBook.sync { XCTAssertTrue(session.connected) }
  }

  func testRefreshAnsweredBusyBacksOffAndIsNotAPermanentFailure() throws {
    try XCTSkipUnless(Reachability.isConnectedToNetwork(), "loginSdk is only sent on a reachable network")
    StubURLProtocol.respond = { request in
      switch request.url!.lastPathComponent {
      case "loginSdk": return self.loginSucceeds()
      case "refreshSdkToken": return StubURLProtocol.Response(status: 503)
      default: return StubURLProtocol.Response(status: 401, body: Data(#"{"name":"TokenExpired","message":"expired"}"#.utf8))
      }
    }
    ShipBook.start(appId: appId, appKey: appKey)
    XCTAssertTrue(loginFinished())

    let before = Date()
    let uploaded = expectation(description: "upload")
    let log = captureInnerLog {
      ConnectionClient.shared.request(url: "sessions/uploadSavedData", data: String?.none, method: .POST) { response in
        XCTAssertEqual(response.statusCode, 401)
        uploaded.fulfill()
      }
      wait(for: [uploaded], timeout: 5)
    }
    XCTAssertFalse(log.contains("check appId/appKey"), log)

    XCTAssertEqual(StubURLProtocol.requests.map { $0.url!.lastPathComponent }, ["loginSdk", "uploadSavedData", "refreshSdkToken"])
    XCTAssertEqual(session.backOffUntil.timeIntervalSince(before), 300, accuracy: 5)
    XCTAssertFalse(session.paused)
    XCTAssertFalse(session.loginFailedPermanently)
    XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path))
  }
}
