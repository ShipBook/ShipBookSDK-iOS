import XCTest
@testable import ShipBookSDK

class StorageManagerTests: XCTestCase {
  private let key = "storage-manager-test"

  override func setUp() {
    super.setUp()
    StorageManager.shared.remove(forKey: key)
    UserDefaults.standard.removeObject(forKey: key)
  }

  func testStoredDataIsReadBack() {
    StorageManager.shared.set(Data("{\"a\":1}".utf8), forKey: key)

    XCTAssertEqual(StorageManager.shared.data(forKey: key), Data("{\"a\":1}".utf8))
  }

  func testRemovedDataIsGone() {
    StorageManager.shared.set(Data("x".utf8), forKey: key)

    StorageManager.shared.remove(forKey: key)

    XCTAssertNil(StorageManager.shared.data(forKey: key))
  }

  func testKeepsItsKeysOutOfTheAppsUserDefaults() {
    StorageManager.shared.set(Data("x".utf8), forKey: key)

    XCTAssertNil(UserDefaults.standard.object(forKey: key))
  }
}
