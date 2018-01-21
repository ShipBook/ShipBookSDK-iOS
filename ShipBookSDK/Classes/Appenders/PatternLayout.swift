//
//  PatternAppender.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 08/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation
protocol PatternLayout {
  var pattern : String { get }
}

extension PatternLayout {
  func color(severity: Severity) -> String {
    switch severity {
    case .Off:
      return ""
    case .Error:
      return "🆘"
    case .Warning:
      return "✴️"
    case .Info:
      return "ℹ️"
    case .Debug:
      return "🛃"
    case .Verbose:
      return "⚛️"
    }
  }

  func toString(message: Message) -> String {
    var messageString = pattern.replacingOccurrences(of: "$datetime", with: message.time.toISO8601Format())
    messageString = messageString.replacingOccurrences(of: "$time", with: message.time.toTimeFormat())
    messageString = messageString.replacingOccurrences(of: "$message", with: message.message)
    messageString = messageString.replacingOccurrences(of: "$severityIcon", with: color(severity: message.severity))
    messageString = messageString.replacingOccurrences(of: "$severity", with: message.severity.name)
    messageString = messageString.replacingOccurrences(of: "$color", with: color(severity: message.severity))
    messageString = messageString.replacingOccurrences(of: "$tag", with: message.tag)
    messageString = messageString.replacingOccurrences(of: "$filename", with: message.file.components(separatedBy: "/").last!)
    messageString = messageString.replacingOccurrences(of: "$file", with: message.file)
    messageString = messageString.replacingOccurrences(of: "$line", with: String(message.line))
    messageString = messageString.replacingOccurrences(of: "$stackTrace", with: message.callStackSymbols != nil ? message.callStackSymbols!.joined(separator: "\n") : "")
    messageString = messageString.replacingOccurrences(of: "$isMainThread", with: String(message.threadInfo.isMain))
    messageString = messageString.replacingOccurrences(of: "$queueLabel", with: message.threadInfo.queueLabel)
    messageString = messageString.replacingOccurrences(of: "$threadName", with: message.threadInfo.threadName)
    messageString = messageString.replacingOccurrences(of: "$threadId", with: String(message.threadInfo.threadId))
    
    
    return messageString
  }
}
