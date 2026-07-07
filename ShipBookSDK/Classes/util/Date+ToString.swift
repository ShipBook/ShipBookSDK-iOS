//
//  Date+ToJavaScriptString.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

extension Date {
  // Cached: per-call DateFormatter allocation crashed under memory pressure (issue #13)
  private static let iso8601Formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter
  }()

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()

  func toISO8601Format() -> String {
    return Self.iso8601Formatter.string(from: self)
  }

  func toTimeFormat() -> String {
    return Self.timeFormatter.string(from: self)
  }
}
