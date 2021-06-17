//
//  InnerLog.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 28/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class InnerLog{
  static var enabled: Bool = false
  
  // static part of the class
  static func e(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    InnerLog.message(msg: msg, severity: .Error, tag: tag, function: function,file: file,line: line)
  }
  
  static func w(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    InnerLog.message(msg: msg, severity: .Warning, tag: tag, function: function,file: file,line: line)
  }
  
  static func i(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    InnerLog.message(msg: msg, severity: .Info, tag: tag, function: function,file: file,line: line)
  }
  
  static func v(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    InnerLog.message(msg: msg, severity: .Verbose, tag: tag, function: function,file: file,line: line)
  }
  
  static func d(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    InnerLog.message(msg: msg, severity: .Debug, tag: tag, function: function,file: file,line: line)
  }
  
  static func message(msg:String,severity:Severity,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    if !enabled {
      return
    }
    print("Shipbook: \(Date().toTimeFormat()) \(severity.name) - \(msg)")
  }

}
