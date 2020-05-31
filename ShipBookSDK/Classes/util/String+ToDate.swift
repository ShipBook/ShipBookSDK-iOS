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
  func toDate() throws -> Date  {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    guard let date = formatter.date(from: self) else {
      throw NoDateError()
    }
    return date
    
  }
}
