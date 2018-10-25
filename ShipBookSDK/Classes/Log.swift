//
//  Log.swift
//  iOSSdk
//
//  Created by Elisha Sterngold on 25/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

fileprivate let appName = Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String ?? ""
/**
  The class that create the logs.
 
  There are two ways that you can call this class:
  1. Getting this class from `ShipBook.getLogger`
  2. Calling static functions. This is not recommended and the caveats are listed below. When a static function activates the logger, the tag will become the filename.
 
  As mentioned, working with this static logger isn’t ideal:
  * Performance is slower, especially in cases where the log is closed
  * The log’s information is less detailed. Ideally, you should create a logger for each class.
  * The Log name can have a name collision with a local Log class.
*/
@objcMembers
public class Log: NSObject {
  // static part of the class
  /**
    Error message
    - Parameters:
      - msg: The message.
      - tag: The tag. If no tag is given then it will be the file name.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
  */
  public static func e(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    Log.message(msg: msg, severity: .Error, tag: tag, function: function,file: file,line: line)
  }

  /**
    Warning message
    - Parameters:
      - msg: The message.
      - tag: The tag. If no tag is given then it will be the file name.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
   */
  public static func w(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    Log.message(msg: msg, severity: .Warning, tag: tag, function: function,file: file,line: line)
  }

  /**
    Information message
    - Parameters:
      - msg: The message.
      - tag: The tag. If no tag is given then it will be the file name.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
  */
  public static func i(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    Log.message(msg: msg, severity: .Info, tag: tag, function: function,file: file,line: line)
  }

  /**
    Debug message
    - Parameters:
      - msg: The message.
      - tag: The tag. If no tag is given then it will be the file name.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
  */
  public static func d(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    Log.message(msg: msg, severity: .Debug, tag: tag, function: function,file: file,line: line)
  }

  /**
    Verbose message
    - Parameters:
      - msg: The message.
      - tag: The tag. If no tag is given then it will be the file name.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
  */
  public static func v(_ msg:String,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    Log.message(msg: msg, severity: .Verbose, tag: tag, function: function,file: file,line: line)
  }
  
  /**
    General message
    - Parameters:
      - msg: The message.
      - severity: The log severity of the message.
      - tag: The tag. If no tag is given then it will be the file name.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
  */
  public static func message(msg:String,severity:Severity,tag:String? = nil,function: String = #function, file: String = #file, line: Int = #line){
    let logClass = Log(tag, file: file)
    logClass.message(msg: msg, severity:severity, function: function, file: file, line: line)
  }
  
  // None  static part of class
  var tag: String
  var severity: Severity
  var callStackSeverity: Severity
  
  init(_ tag: String?, file: String = #file) {
    var tempTag = tag
    if tempTag == nil  { // for the case that there is no tag
      let lastPath = (file as NSString).lastPathComponent
      tempTag = lastPath.components(separatedBy: ".swift")[0]
    }
    
    self.tag = "\(appName).\(tempTag!)"
    severity = LogManager.shared.getSeverity(self.tag)
    callStackSeverity = LogManager.shared.getCallStackSeverity(self.tag)
    super.init()
    addNotification()
  }
  
  init(_ klass: AnyClass) {
    self.tag = String(reflecting: klass)
    self.severity = LogManager.shared.getSeverity(tag)
    self.callStackSeverity = LogManager.shared.getCallStackSeverity(tag)
    super.init()
    addNotification()
  }
  
  private func addNotification () {
    weak var _self = self
    NotificationCenter.default.addObserver(
      forName: NotificationName.ConfigChange,
      object: nil,
      queue: nil) { (notification) in
        if let _self = _self {
          _self.severity = LogManager.shared.getSeverity(self.tag)
          _self.callStackSeverity = LogManager.shared.getCallStackSeverity(self.tag)
        }
    }
  }

  /**
    Error message
    - Parameters:
      - msg: The message.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
  */
  public func e(_ msg:String, function: String = #function, file: String = #file, line: Int = #line){
    message(msg: msg, severity: .Error, function: function,file: file,line: line)
  }

  /**
    Warning message
    - Parameters:
      - msg: The message.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
   */
  public  func w(_ msg:String, function: String = #function, file: String = #file, line: Int = #line){
    message(msg: msg, severity: .Warning, function: function,file: file,line: line)
  }
  
  /**
    Information message
    - Parameters:
      - msg: The message.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
   */
  public func i(_ msg:String, function: String = #function, file: String = #file, line: Int = #line){
    message(msg: msg, severity: .Info, function: function,file: file,line: line)
  }
  
  /**
    Debug message
    - Parameters:
      - msg: The message.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
  */
  public func d(_ msg:String, function: String = #function, file: String = #file, line: Int = #line){
    message(msg: msg, severity: .Debug, function: function,file: file,line: line)
  }

  /**
    Verbose message
    - Parameters:
      - msg: The message.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
   */
  public func v(_ msg:String, function: String = #function, file: String = #file, line: Int = #line){
    message(msg: msg, severity: .Verbose, function: function,file: file,line: line)
  }

  /**
    Checking if the severity is enabled.
   
    Is needed in the case that the user wants to do calculations just for the log. In this case when the log is closed the it shouldn't do the calculation.
   
    - Parameters:
      - severety: The severity to check.
  */
  public func isEnabled(_ severity: Severity) -> Bool {
    return severity.rawValue <= self.severity.rawValue
  }

  /**
    General message
    - Parameters:
      - msg: The message.
      - severity: The log severity of the message.
      - function: The function that the log is written in.
      - file: The file that the log is written in.
      - line: The line number that the log is written in.
  */
  public func message(msg:String, severity:Severity, function: String = #function, file: String = #file, line: Int = #line) {
    if (severity.rawValue > self.severity.rawValue) { return }
    var callStackSymbols: [String]? = nil
    if (severity.rawValue <= callStackSeverity.rawValue) { callStackSymbols = Thread.callStackSymbols }
    let messageObj = Message(message: msg, severity:severity, tag: self.tag, function: function, file: file, line: line, callStackSymbols: callStackSymbols)
    LogManager.shared.push(log: messageObj)
  }
}
