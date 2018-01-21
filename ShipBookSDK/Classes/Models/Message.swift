//
//  LogMessage.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 29/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class Message: BaseLog {
  var tag: String
  var severity: Severity
  var message: String
  var function: String
  var file: String
  var line: Int
  var callStackSymbols: [String]?

  init(message: String, severity: Severity, tag: String, function: String, file: String, line: Int, callStackSymbols: [String]? = nil) {
    self.message = message
    self.tag = tag
    self.severity = severity
    self.function = function
    self.file = file
    self.line = line
    self.callStackSymbols = callStackSymbols
    super.init(type: "message")
  }
  
  enum CodingKeys: String, CodingKey {
    case message
    case tag
    case severity
    case function
    case file = "fileName"
    case line = "lineNumber"
    case callStackSymbols
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.message = try container.decode(String.self, forKey: .message)
    self.tag = try container.decode(String.self, forKey: .tag)
    self.severity = try container.decode(Severity.self, forKey: .severity)
    self.function = try container.decode(String.self, forKey: .function)
    self.file = try container.decode(String.self, forKey: .file)
    self.line = try container.decode(Int.self, forKey: .line)
    self.callStackSymbols = try container.decodeIfPresent(Array.self, forKey: .callStackSymbols)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(message, forKey: .message)
    try container.encode(tag, forKey: .tag)
    try container.encode(severity, forKey: .severity)
    try container.encode(function, forKey: .function)
    try container.encode(file, forKey: .file)
    try container.encode(line, forKey: .line)
    try container.encodeIfPresent(callStackSymbols, forKey: .callStackSymbols)
    try super.encode(to: encoder)
  }
}

func ==(lhs: Message, rhs: Message) -> Bool {
  return lhs.time.toISO8601Format() == rhs.time.toISO8601Format() &&
    lhs.message == rhs.message &&
    lhs.tag == rhs.tag &&
    lhs.severity == rhs.severity &&
    lhs.function == rhs.function &&
    lhs.file == rhs.file &&
    lhs.line == rhs.line &&
    lhs.threadInfo == rhs.threadInfo
}

