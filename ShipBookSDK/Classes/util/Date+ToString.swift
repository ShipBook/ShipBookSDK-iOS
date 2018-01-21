//
//  Date+ToJavaScriptString.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

extension Date {
  func toISO8601Format() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter.string(from: self)
  }
  
  func toTimeFormat() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: self)
  }
}
