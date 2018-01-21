//
//  Exception.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 15/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class Exception : BaseLog  {
  var name: String
  var reason: String? = nil
  //var userInfo: [AnyHashable : Any]?
  var callStackSymbols: [String]?
  
  init(name: String, reason: String? = nil, callStackSymbols: [String]? = nil) {
    self.name = name
    self.reason = reason
//    self.threadInfo = ThreadInfo()
    self.callStackSymbols = callStackSymbols
    super.init(type:"exception")
  }

  enum CodingKeys: String, CodingKey {
    case name
    case reason
    case callStackSymbols
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
    self.callStackSymbols = try container.decodeIfPresent(Array.self, forKey: .callStackSymbols)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encodeIfPresent(reason, forKey: .reason)
    try container.encodeIfPresent(callStackSymbols, forKey: .callStackSymbols)
    try super.encode(to: encoder)
  }
}

func ==(lhs: Exception, rhs: Exception) -> Bool {
  return lhs.time.toISO8601Format() == rhs.time.toISO8601Format() &&
    lhs.name == rhs.name &&
    lhs.reason == rhs.reason &&
    // TODO: add stackTrace
//    (lhs.stackTrace?)! == (rhs.stackTrace?)! &&
    lhs.threadInfo == rhs.threadInfo 
}


