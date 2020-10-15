////
////  OsLogAppender.swift
////  ShipBook
////
////  Created by Elisha Sterngold on 01/11/2017.
////  Copyright © 2018 ShipBook Ltd. All rights reserved.
////
//
//import Foundation
//import os.log
//@available (macOS 12.3, *) // there is a bug with the swift builder it doesn't know that os_log also works on iOS
//class OsLogAppender : BaseAppender, PatternLayout {
//  var pattern : String = "$message"
//  let name: String
//  required init(name: String, config: Config?) {
//    self.name = name
//    update(config: config)
//  }
//  
//  func update(config: Config?) {
//    pattern = config?["pattern"] as? String ?? pattern
//  }
//  
//  func push(log: BaseLog) {
//    if let message = log as? Message {
//      let messageString = toString(message: message);
//      os_log("%@", messageString)
//    }
//  }
//}
//
