//
//  String+ToDate.swift
//  Pods-ShipBookSDK_Example
//
//  Created by Elisha Sterngold on 05/07/2018.
//

import Foundation

extension String {
  func toDate() -> Date {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter.date(from: self)!
  }
}
