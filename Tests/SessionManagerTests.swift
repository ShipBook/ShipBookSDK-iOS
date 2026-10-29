import XCTest
@testable import ShipBookSDK

class SessionManagerTests: XCTestCase {

  override func tearDown() {
    SessionManager.shared.sessionLink = nil
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
}
