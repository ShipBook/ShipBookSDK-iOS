//
//  ConsoleAppender.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 29/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation
import OSLog

class ConsoleAppender : BaseAppender, PatternLayout {
  var pattern: String = "$message"
  let name: String
  
  required init(name: String, config:Config?) {
    self.name = name
    update(config: config)
  }
  func update(config: Config?) {
    pattern = config?["pattern"] as? String ?? pattern
  }
  
  func push(log: BaseLog) {
    if let message = log as? Message {
      
      if #available(iOS 14.0, *) {
        let subsystem = Bundle.main.bundleIdentifier!
        let logger = Logger(subsystem: subsystem, category: message.tag)
        switch message.severity {
          case Severity.Verbose:
            logger.trace("\(message.message)")
          case Severity.Debug:
            logger.debug("\(message.message)")
          case Severity.Info:
            logger.info("\(message.message)")
          case Severity.Warning:
            logger.warning("\(message.message)")
          case Severity.Error:
            logger.error("\(message.message)")
          default:
            logger.log(level: .default, "\(message.message)")
        }
      }
      else {
        let messageString = toString(message: message);
        print(messageString)
      }
    }
  }
  
  func flush() {
    // empty
  }
  
  func saveCrash(exception: Exception) {
    // empty
  }
}
