import XCTest
@testable import ShipBookSDK

class StubURLProtocol: URLProtocol {
  struct Response {
    var status = 200
    var headers = [String: String]()
    var body = Data()
  }

  private static let lock = NSLock()
  private static var recorded = [URLRequest]()
  private static var originalSession: URLSession?
  static var respond: (URLRequest) -> Response = { _ in Response() }
  static var gate: DispatchSemaphore?

  static var requests: [URLRequest] {
    lock.lock()
    defer { lock.unlock() }
    return recorded
  }

  static func install() {
    lock.lock()
    recorded = []
    lock.unlock()
    respond = { _ in Response() }
    gate = nil
    originalSession = ConnectionClient.shared.session
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    ConnectionClient.shared.session = URLSession(configuration: configuration)
  }

  static func uninstall() {
    gate?.signal()
    gate = nil
    ConnectionClient.shared.session = originalSession!
  }

  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    StubURLProtocol.lock.lock()
    StubURLProtocol.recorded.append(request)
    StubURLProtocol.lock.unlock()
    StubURLProtocol.gate?.wait()
    let stub = StubURLProtocol.respond(request)
    let response = HTTPURLResponse(url: request.url!, statusCode: stub.status, httpVersion: "HTTP/1.1", headerFields: stub.headers)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: stub.body)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

extension XCTestCase {
  func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
      if Date() > deadline { return false }
      RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
    return true
  }

  func assertNoRequest(file: StaticString = #filePath, line: UInt = #line) {
    DispatchQueue.shipBook.sync {}
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    XCTAssertEqual(StubURLProtocol.requests.map { $0.url!.lastPathComponent }, [], file: file, line: line)
  }

  func innerLogTime(_ date: Date) -> String {
    return ISO8601DateFormatter().string(from: date)
  }

  func captureInnerLog(_ block: () -> Void) -> String {
    let wasEnabled = InnerLog.enabled
    InnerLog.enabled = true
    let pipe = Pipe()
    let original = dup(STDOUT_FILENO)
    fflush(stdout)
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    block()
    fflush(stdout)
    dup2(original, STDOUT_FILENO)
    close(original)
    pipe.fileHandleForWriting.closeFile()
    InnerLog.enabled = wasEnabled
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
  }
}

class ConnectionClientTests: XCTestCase {
  private let session = SessionManager.shared
  private let appId = "5f0000000000000000000001"
  private let maxPause: TimeInterval = 30 * 24 * 60 * 60

  override func setUp() {
    super.setUp()
    StubURLProtocol.install()
    resetSession()
  }

  override func tearDown() {
    StubURLProtocol.uninstall()
    resetSession()
    super.tearDown()
  }

  private func resetSession() {
    session.appId = nil
    session.appKey = nil
    session.token = nil
    session.sessionLink = nil
    session.pausedUntil = .distantPast
    session.backOffUntil = .distantPast
    try? FileManager.default.removeItem(at: session.pauseURL)
  }

  private func response(status: Int, headers: [String: String] = [:]) -> ResponseData {
    let url = URL(string: ConnectionClient.BASE_URL + "auth/loginSdk")!
    return ResponseData(response: HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers), data: nil)
  }

  private func send(_ url: String = "sessions/uploadSavedData") -> ResponseData {
    let done = expectation(description: url)
    var result: ResponseData!
    ConnectionClient.shared.request(url: url, data: String?.none, method: .POST) { response in
      result = response
      done.fulfill()
    }
    wait(for: [done], timeout: 5)
    return result
  }

  private func respond(status: Int, headers: [String: String] = [:]) {
    StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: status, headers: headers) }
  }

  // MARK: reading the two signals

  func testPauseHeaderIsARefusalOnAnyErrorStatus() {
    for status in [400, 401, 429, 500, 503] {
      let refused = response(status: status, headers: ["x-shipbook-pause": "120", "Retry-After": "120"])
      XCTAssertEqual(refused.pause, 120, "\(status)")
      XCTAssertFalse(refused.busy, "\(status)")
    }
  }

  func testPauseHeaderNameIsCaseInsensitive() {
    XCTAssertEqual(response(status: 401, headers: ["X-Shipbook-Pause": "120"]).pause, 120)
    XCTAssertEqual(response(status: 401, headers: ["X-SHIPBOOK-PAUSE": "120"]).pause, 120)
    XCTAssertEqual(response(status: 429, headers: ["RETRY-AFTER": "60"]).retryAfter, 60)
  }

  func testPauseHeaderThatIsNotAPositiveIntegerCountsAsAbsent() {
    for value in ["abc", "", "1.5", "12s", "Wed, 21 Oct 2026 07:28:00 GMT", "0", "-5"] {
      XCTAssertNil(response(status: 401, headers: ["x-shipbook-pause": value]).pause, value)
      XCTAssertFalse(response(status: 401, headers: ["x-shipbook-pause": value]).busy, value)
      XCTAssertNil(response(status: 429, headers: ["x-shipbook-pause": value]).pause, value)
      XCTAssertTrue(response(status: 429, headers: ["x-shipbook-pause": value]).busy, value)
    }
  }

  func testPauseHeaderBelowStatus400IsIgnored() {
    XCTAssertNil(response(status: 200, headers: ["x-shipbook-pause": "120"]).pause)
    XCTAssertNil(response(status: 304, headers: ["x-shipbook-pause": "120"]).pause)
  }

  func testRetryAfterAloneIsNotARefusal() {
    for status in [400, 401, 403, 404, 500, 502, 504] {
      let answer = response(status: status, headers: ["Retry-After": "120"])
      XCTAssertNil(answer.pause, "\(status)")
      XCTAssertFalse(answer.busy, "\(status)")
    }
  }

  func testOnlyA429OrA503WithoutAPauseIsBusy() {
    XCTAssertTrue(response(status: 429).busy)
    XCTAssertTrue(response(status: 503).busy)
    XCTAssertEqual(response(status: 429, headers: ["Retry-After": "120"]).retryAfter, 120)
    XCTAssertEqual(response(status: 503, headers: ["retry-after": "45"]).retryAfter, 45)
    for value in ["abc", "", "1.5", "Wed, 21 Oct 2026 07:28:00 GMT", "0", "-5"] {
      XCTAssertNil(response(status: 429, headers: ["Retry-After": value]).retryAfter, value)
    }
    for status in [200, 400, 401, 404, 500, 502, 504] {
      XCTAssertFalse(response(status: status).busy, "\(status)")
    }
  }

  // MARK: request headers

  func testRequestsIdentifyTheAppAndTheSdk() {
    session.appId = appId

    XCTAssertTrue(send().ok)

    let request = StubURLProtocol.requests[0]
    XCTAssertEqual(request.value(forHTTPHeaderField: "x-shipbook-app-id"), appId)
    XCTAssertEqual(request.value(forHTTPHeaderField: "x-shipbook-sdk"), "ios/\(shipBookSDKVersion)")
  }

  func testRequestsBeforeStartCarryNoAppId() {
    XCTAssertTrue(send().ok)

    let request = StubURLProtocol.requests[0]
    XCTAssertNil(request.value(forHTTPHeaderField: "x-shipbook-app-id"))
    XCTAssertEqual(request.value(forHTTPHeaderField: "x-shipbook-sdk"), "ios/\(shipBookSDKVersion)")
  }

  // MARK: pause

  func testPauseHeaderOnA401PausesClearsTheSessionAndIsStored() throws {
    session.appId = appId
    session.token = "token"
    session.sessionLink = "1:app:session"
    respond(status: 401, headers: ["x-shipbook-pause": "120", "retry-after": "120"])

    let before = Date()
    var response: ResponseData!
    let log = captureInnerLog { response = send() }

    XCTAssertEqual(response.statusCode, 401)
    XCTAssertTrue(session.paused)
    XCTAssertEqual(session.pausedUntil.timeIntervalSince(before), 120, accuracy: 5)
    XCTAssertEqual(session.backOffUntil, .distantPast)
    XCTAssertNil(session.token)
    XCTAssertEqual(ShipBook.getSessionHeaders(), [:])
    XCTAssertTrue(log.contains("Warning - paused until \(innerLogTime(session.pausedUntil)): the server answered 401 with x-shipbook-pause 120\n"), log)
    XCTAssertNotNil(log.range(of: #"paused until \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z: the server"#, options: .regularExpression), log)

    let stored = try JSONSerialization.jsonObject(with: Data(contentsOf: session.pauseURL)) as! [String: Any]
    XCTAssertEqual(Set(stored.keys), ["appId", "sdkVersion", "until"])
    XCTAssertEqual(stored["appId"] as? String, appId)
    XCTAssertEqual(stored["sdkVersion"] as? String, shipBookSDKVersion)
    XCTAssertEqual((stored["until"] as! NSNumber).int64Value, Int64(session.pausedUntil.timeIntervalSince1970 * 1000))
  }

  func testPauseHeaderOnA429PausesInsteadOfBackingOff() {
    session.appId = appId
    session.token = "token"
    respond(status: 429, headers: ["X-Shipbook-Pause": "7200", "Retry-After": "7200"])

    let before = Date()
    let log = captureInnerLog { XCTAssertEqual(send().statusCode, 429) }

    XCTAssertEqual(session.pausedUntil.timeIntervalSince(before), 7200, accuracy: 5)
    XCTAssertEqual(session.backOffUntil, .distantPast)
    XCTAssertNil(session.token)
    XCTAssertTrue(FileManager.default.fileExists(atPath: session.pauseURL.path))
    XCTAssertTrue(log.contains("Warning - paused until \(innerLogTime(session.pausedUntil)): the server answered 429 with x-shipbook-pause 7200\n"), log)
    XCTAssertFalse(log.contains("backing off"), log)
  }

  func testPauseIsCappedAt30Days() {
    session.appId = appId
    for (value, expected) in [("2592000", maxPause), ("2592001", maxPause), ("999999999", maxPause), ("2591999", maxPause - 1)] {
      session.pausedUntil = .distantPast
      respond(status: 401, headers: ["x-shipbook-pause": value])

      let before = Date()
      let log = captureInnerLog { _ = send() }

      XCTAssertEqual(session.pausedUntil.timeIntervalSince(before), expected, accuracy: 0.5, value)
      XCTAssertTrue(log.contains("the server answered 401 with x-shipbook-pause \(value)\n"), log)
    }
  }

  func testWhilePausedRequestsAreAnsweredLocallyWithA429() {
    session.appId = appId
    let until = Date().addingTimeInterval(600)
    session.pausedUntil = until

    let log = captureInnerLog {
      for url in ["auth/loginSdk", "auth/refreshSdkToken", "sessions/uploadSavedData"] {
        let response = send(url)
        XCTAssertFalse(response.ok)
        XCTAssertEqual(response.statusCode, 429)
      }
    }

    assertNoRequest()
    XCTAssertEqual(session.pausedUntil, until)
    XCTAssertEqual(session.backOffUntil, .distantPast)
    XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path))
    XCTAssertFalse(log.contains("paused"), log)
    XCTAssertFalse(log.contains("backing off"), log)
  }

  // MARK: back-off

  func testA429OrA503BacksOffForRetryAfterAndStoresNothing() {
    session.appId = appId
    session.token = "token"
    session.sessionLink = "1:app:session"
    for status in [429, 503] {
      session.backOffUntil = .distantPast
      respond(status: status, headers: ["Retry-After": "120"])

      let before = Date()
      var response: ResponseData!
      let log = captureInnerLog { response = send() }

      XCTAssertEqual(response.statusCode, status)
      XCTAssertEqual(session.backOffUntil.timeIntervalSince(before), 120, accuracy: 5, "\(status)")
      XCTAssertTrue(session.requestsBlocked, "\(status)")
      XCTAssertFalse(session.paused, "\(status)")
      XCTAssertEqual(session.token, "token", "\(status)")
      XCTAssertEqual(ShipBook.getSessionHeaders(), ["x-shipbook-session": "1:app:session"], "\(status)")
      XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path), "\(status)")
      XCTAssertTrue(log.contains("Warning - backing off until \(innerLogTime(session.backOffUntil)): the server answered \(status)\n"), log)
      XCTAssertNotNil(log.range(of: #"backing off until \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z: the server"#, options: .regularExpression), log)
      XCTAssertFalse(log.contains("paused"), log)
    }
  }

  func testBackOffIs300SecondsWithoutAUsableRetryAfterAndAtMostAnHour() {
    let cases: [(headers: [String: String], seconds: TimeInterval)] = [
      ([:], 300),
      (["Retry-After": "abc"], 300),
      (["Retry-After": "0"], 300),
      (["Retry-After": "Wed, 21 Oct 2026 07:28:00 GMT"], 300),
      (["Retry-After": "1"], 1),
      (["Retry-After": "3600"], 3600),
      (["Retry-After": "3601"], 3600),
      (["Retry-After": "86400"], 3600),
      (["x-shipbook-pause": "0", "Retry-After": "60"], 60),
    ]
    for status in [429, 503] {
      for (headers, seconds) in cases {
        session.backOffUntil = .distantPast
        respond(status: status, headers: headers)

        let before = Date()
        _ = send()

        XCTAssertEqual(session.backOffUntil.timeIntervalSince(before), seconds, accuracy: 0.5, "\(status) \(headers)")
        XCTAssertFalse(session.paused, "\(status) \(headers)")
      }
    }
  }

  func testWhileBackingOffRequestsAreAnsweredLocallyWithA429() {
    session.appId = appId
    session.token = "token"
    let until = Date().addingTimeInterval(600)
    session.backOffUntil = until

    let log = captureInnerLog {
      for url in ["auth/loginSdk", "auth/refreshSdkToken", "sessions/uploadSavedData"] {
        let response = send(url)
        XCTAssertFalse(response.ok)
        XCTAssertEqual(response.statusCode, 429)
      }
    }

    assertNoRequest()
    XCTAssertEqual(session.backOffUntil, until)
    XCTAssertFalse(session.paused)
    XCTAssertEqual(session.token, "token")
    XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path))
    XCTAssertFalse(log.contains("backing off"), log)
  }

  // MARK: neither signal

  func testRetryAfterOnA401ChangesNothing() {
    session.appId = appId
    session.token = "token"
    respond(status: 401, headers: ["Retry-After": "120"])

    let log = captureInnerLog { XCTAssertEqual(send().statusCode, 401) }

    XCTAssertFalse(session.requestsBlocked)
    XCTAssertEqual(session.token, "token")
    XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path))
    XCTAssertFalse(log.contains("paused"), log)
    XCTAssertFalse(log.contains("backing off"), log)
    XCTAssertTrue(send().statusCode == 401)
    XCTAssertEqual(StubURLProtocol.requests.count, 2)
  }

  func testOtherErrorsWithoutASignalChangeNothing() {
    session.appId = appId
    session.token = "token"
    for status in [400, 404, 500, 502, 504] {
      respond(status: status, headers: ["Retry-After": "120"])

      let log = captureInnerLog { XCTAssertEqual(send().statusCode, status) }

      XCTAssertFalse(session.requestsBlocked, "\(status)")
      XCTAssertEqual(session.token, "token", "\(status)")
      XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path), "\(status)")
      XCTAssertFalse(log.contains("paused") || log.contains("backing off"), log)
    }
  }

  func testRequestsGoOutAgainWhenThePauseAndTheBackOffAreOver() {
    session.pausedUntil = Date().addingTimeInterval(-1)
    session.backOffUntil = Date().addingTimeInterval(-1)

    XCTAssertTrue(send().ok)
    XCTAssertEqual(StubURLProtocol.requests.count, 1)
  }
}
