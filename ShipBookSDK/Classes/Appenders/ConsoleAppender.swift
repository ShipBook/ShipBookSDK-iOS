//
//  ConsoleAppender.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 29/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

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
      let messageString = toString(message: message);
      print(messageString)
    }
  }
  
  func flush() {
    // empty
  }
  
  func saveCrash(exception: Exception) {
    // empty
  }
}
