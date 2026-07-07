//
//  String+ToDate.swift
//  Pods-ShipBookSDK_Example
//
//  Created by Elisha Sterngold on 05/07/2018.
//

import Foundation
struct NoDateError: Error {
}

extension String {
  // Cached: per-call DateFormatter allocation crashed under memory pressure (issue #13)
  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter
  }()

  func toDate() throws -> Date  {
    guard let date = Self.dateFormatter.date(from: self) else {
      throw NoDateError()
    }
    return date
  }
}
