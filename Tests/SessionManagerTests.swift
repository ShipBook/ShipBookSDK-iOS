import XCTest
@testable import ShipBookSDK

// Refuses every request, so login() never reaches the real server.
private class RefusingURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Data())
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {
  }
}

class SessionManagerTests: XCTestCase {
  private let cachedConfig = """
  {
    "appenders": [{ "type": "ConsoleAppender", "name": "cachedConsole", "config": { "pattern": "$message" } }],
    "loggers": [{ "name": "", "severity": "Verbose", "appenderRef": "cachedConsole" }]
  }
  """
  private var originalSession: URLSession!

  override func setUp() {
    super.setUp()
    originalSession = ConnectionClient.shared.session
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [RefusingURLProtocol.self]
    ConnectionClient.shared.session = URLSession(configuration: configuration)
    StorageManager.shared.remove(forKey: "config")
    LogManager.shared.clear()
  }

  override func tearDown() {
    SessionManager.shared.sessionLink = nil
    StorageManager.shared.remove(forKey: "config")
    LogManager.shared.clear()
    ConnectionClient.shared.session = originalSession
    super.tearDown()
  }

  func testSessionHeadersCarryTheSessionLink() {
    SessionManager.shared.sessionLink = "1:698ad6e6595b3f6a7590b24f:66f1c2a9e4b0d3f8a1b2c3d4"
    XCTAssertEqual(ShipBook.getSessionHeaders(), ["x-shipbook-session": "1:698ad6e6595b3f6a7590b24f:66f1c2a9e4b0d3f8a1b2c3d4"])
  }

  func testSessionHeadersAreEmptyBeforeLogin() {
    SessionManager.shared.sessionLink = nil
    XCTAssertEqual(ShipBook.getSessionHeaders(), [:])
  }

  func testCorruptCachedConfigIsRemovedAndTheDefaultConfigUsed() {
    StorageManager.shared.set(Data("not json".utf8), forKey: "config")

    SessionManager.shared.login(appId: "appId", appKey: "appKey", completion: nil)
    DispatchQueue.shipBook.sync {}

    XCTAssertNil(StorageManager.shared.data(forKey: "config"), "a corrupt cache must be removed so the next start doesn't hit it again")
    XCTAssertEqual(Set(LogManager.shared.appenders.keys), ["console", "cloud"])
  }

  func testValidCachedConfigIsUsed() {
    StorageManager.shared.set(Data(cachedConfig.utf8), forKey: "config")

    SessionManager.shared.login(appId: "appId", appKey: "appKey", completion: nil)
    DispatchQueue.shipBook.sync {}

    XCTAssertEqual(StorageManager.shared.data(forKey: "config"), Data(cachedConfig.utf8))
    XCTAssertEqual(Set(LogManager.shared.appenders.keys), ["cachedConsole"])
  }
}
