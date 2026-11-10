#if canImport(UIKit)
import Foundation

// The SDK's own suite, never UserDefaults.standard, so its keys can't collide with the app's.
class StorageManager {
  private let defaults = UserDefaults(suiteName: "io.shipbook.shipbooksdk")!

  private init(){
  }

  static let shared = StorageManager()

  func data(forKey key: String) -> Data? {
    return defaults.data(forKey: key)
  }

  func set(_ data: Data, forKey key: String) {
    defaults.set(data, forKey: key)
  }

  func remove(forKey key: String) {
    defaults.removeObject(forKey: key)
  }
}
#endif
