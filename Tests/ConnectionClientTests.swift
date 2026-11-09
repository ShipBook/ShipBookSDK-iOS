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

  func testRetryAfterSecondsPauseForThatLong() {
    XCTAssertEqual(response(status: 401, headers: ["Retry-After": "120"]).pause, 120)
    XCTAssertEqual(response(status: 429, headers: ["Retry-After": "7200"]).pause, 7200)
    XCTAssertEqual(response(status: 503, headers: ["Retry-After": "1"]).pause, 1)
  }

  func testRetryAfterHeaderNameIsCaseInsensitive() {
    XCTAssertEqual(response(status: 401, headers: ["retry-after": "120"]).pause, 120)
    XCTAssertEqual(response(status: 401, headers: ["RETRY-AFTER": "120"]).pause, 120)
  }

  func testA4xxWithoutRetryAfterDoesNotPause() {
    XCTAssertNil(response(status: 401).pause)
    XCTAssertNil(response(status: 400, headers: ["Content-Type": "application/json"]).pause)
  }

  func testRetryAfterThatIsNotAPositiveIntegerIsIgnored() {
    for value in ["abc", "", "1.5", "12s", "Wed, 21 Oct 2026 07:28:00 GMT", "0", "-5"] {
      XCTAssertNil(response(status: 401, headers: ["Retry-After": value]).pause, value)
      XCTAssertNil(response(status: 401, headers: ["Retry-After": value]).retryAfter, value)
    }
  }

  func testRetryAfterIsCappedAt30Days() {
    XCTAssertEqual(response(status: 401, headers: ["Retry-After": "2592000"]).pause, maxPause)
    XCTAssertEqual(response(status: 401, headers: ["Retry-After": "2592001"]).pause, maxPause)
    XCTAssertEqual(response(status: 429, headers: ["Retry-After": "999999999"]).pause, maxPause)
  }

  func testStatus429WithoutAUsableRetryAfterPausesOneHour() {
    XCTAssertEqual(response(status: 429).pause, 3600)
    XCTAssertEqual(response(status: 429, headers: ["Retry-After": "abc"]).pause, 3600)
    XCTAssertEqual(response(status: 429, headers: ["Retry-After": "0"]).pause, 3600)
  }

  func testRetryAfterBelowStatus400IsIgnored() {
    XCTAssertNil(response(status: 200, headers: ["Retry-After": "120"]).pause)
    XCTAssertNil(response(status: 304, headers: ["Retry-After": "120"]).pause)
  }

  func testRequestsIdentifyTheAppAndTheSdk() {
    session.appId = "5f0000000000000000000001"

    XCTAssertTrue(send().ok)

    let request = StubURLProtocol.requests[0]
    XCTAssertEqual(request.value(forHTTPHeaderField: "x-shipbook-app-id"), "5f0000000000000000000001")
    XCTAssertEqual(request.value(forHTTPHeaderField: "x-shipbook-sdk"), "ios/\(shipBookSDKVersion)")
  }

  func testRequestsBeforeStartCarryNoAppId() {
    XCTAssertTrue(send().ok)

    let request = StubURLProtocol.requests[0]
    XCTAssertNil(request.value(forHTTPHeaderField: "x-shipbook-app-id"))
    XCTAssertEqual(request.value(forHTTPHeaderField: "x-shipbook-sdk"), "ios/\(shipBookSDKVersion)")
  }

  func testPauseSignalPausesClearsTheSessionAndIsStored() throws {
    session.appId = "5f0000000000000000000001"
    session.token = "token"
    session.sessionLink = "1:app:session"
    StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: 401, headers: ["retry-after": "120"]) }

    let before = Date()
    var response: ResponseData!
    let log = captureInnerLog { response = send() }

    XCTAssertEqual(response.statusCode, 401)
    XCTAssertTrue(session.paused)
    XCTAssertEqual(session.pausedUntil.timeIntervalSince(before), 120, accuracy: 5)
    XCTAssertNil(session.token)
    XCTAssertEqual(ShipBook.getSessionHeaders(), [:])
    XCTAssertTrue(log.contains("Warning - Shipbook paused until \(session.pausedUntil.toISO8601Format()): the server answered 401 with Retry-After 120\n"), log)

    let stored = try JSONSerialization.jsonObject(with: Data(contentsOf: session.pauseURL)) as! [String: Any]
    XCTAssertEqual(Set(stored.keys), ["appId", "sdkVersion", "until"])
    XCTAssertEqual(stored["appId"] as? String, "5f0000000000000000000001")
    XCTAssertEqual(stored["sdkVersion"] as? String, shipBookSDKVersion)
    XCTAssertEqual((stored["until"] as! NSNumber).int64Value, Int64(session.pausedUntil.timeIntervalSince1970 * 1000))
  }

  func testA429WithoutRetryAfterPausesOneHourAndSaysSoInTheInnerLog() {
    session.appId = "5f0000000000000000000001"
    StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: 429) }

    let before = Date()
    let log = captureInnerLog { _ = send() }

    XCTAssertEqual(session.pausedUntil.timeIntervalSince(before), 3600, accuracy: 5)
    XCTAssertTrue(log.contains("Warning - Shipbook paused until \(session.pausedUntil.toISO8601Format()): the server answered 429 without Retry-After\n"), log)
  }

  func testA4xxWithoutPauseSignalDoesNotPauseOrStoreAnything() {
    session.appId = "5f0000000000000000000001"
    session.token = "token"
    StubURLProtocol.respond = { _ in StubURLProtocol.Response(status: 400) }

    let log = captureInnerLog { XCTAssertEqual(send().statusCode, 400) }

    XCTAssertFalse(session.paused)
    XCTAssertEqual(session.token, "token")
    XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path))
    XCTAssertFalse(log.contains("paused"), log)
  }

  func testWhilePausedRequestsAreAnsweredLocallyWithA429() {
    session.appId = "5f0000000000000000000001"
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
    XCTAssertFalse(FileManager.default.fileExists(atPath: session.pauseURL.path))
    XCTAssertFalse(log.contains("paused"), log)
  }

  func testRequestsGoOutAgainWhenThePauseIsOver() {
    session.pausedUntil = Date().addingTimeInterval(-1)

    XCTAssertTrue(send().ok)
    XCTAssertEqual(StubURLProtocol.requests.count, 1)
  }
}
