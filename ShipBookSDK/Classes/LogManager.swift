//
//  LogManager.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 29/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class LogManager {
  struct Logger {
    var key: String
    var severity: Severity
    var callStackSeverity: Severity
    var appender: BaseAppender
  }
  
  typealias AppenderDictionary = [String:BaseAppender]
  var appenders = AppenderDictionary()
  var loggers = [Logger]()
  
  private init(){
  }
  
  static let shared = LogManager()
  
  func clear() {
    DispatchQueue.shipBook.async {
      self.appenders.removeAll()
      self.loggers.removeAll()
    }
  }
  
  func add(appender: BaseAppender, name: String) {
    DispatchQueue.shipBook.async {
      self.appenders[name] = appender
    }
  }
  
  func remove(appenderName: String){
    DispatchQueue.shipBook.async {
      self.appenders[appenderName] = nil
    }
  }
  
  func add(module: String, severity: Severity, callStackSeverity: Severity, appender: String){
    DispatchQueue.shipBook.async {
      if let appenderObj = self.appenders[appender] {
        self.loggers.append(Logger(key: module, severity: severity, callStackSeverity: callStackSeverity, appender: appenderObj))
      }
    }
  }
  
  func remove(module: String){
    // TODO: implement it
  }
  
  func push(log: BaseLog) {
    if let message = log as? Message { //is a message going according to tags
      let loggers = self.loggers //so that if something happens asynchronous it won't disturb
      let appenders = self.appenders //so that if something happens asynchronous it won't disturb
      var appenderNames = Set<String>()
      
      for logger in loggers {
        if message.tag.starts(with: logger.key) && message.severity.rawValue <= logger.severity.rawValue {
          appenderNames.insert(logger.appender.name)
        }
      }
      
      for appenderName in appenderNames {
        appenders[appenderName]?.push(log: message)
      }
    }
    else { // isn't a message and therefor there isn't any tags
      let appenders = self.appenders //so that if something happens asynchronous it won't disturb
      for appender in appenders.values {
        appender.push(log:log)
      }
    }
  }
  
  func getLevel(_ tag: String) -> Severity {
    let loggers = self.loggers // so that if something happens asynchronous it won't disturb
    var severity = Severity.Off
    for logger in loggers {
      if tag.starts(with: logger.key) && logger.severity.rawValue > severity.rawValue {
        severity = logger.severity
      }
    }
    
    return severity
  }

  func getCallStackLevel(_ tag: String) -> Severity {
    let loggers = self.loggers // so that if something happens asynchronous it won't disturb
    var callStackSeverity = Severity.Off
    for logger in loggers {
      if tag.starts(with: logger.key) && logger.callStackSeverity.rawValue > callStackSeverity.rawValue {
        callStackSeverity = logger.callStackSeverity
      }
    }
    
    return callStackSeverity
  }

  func config(_ config: ConfigResponse) {
    DispatchQueue.shipBook.async {
      // appenders
      var appenders = AppenderDictionary()
      for appender in config.appenders {
        if let origAppender = self.appenders[appender.name] {
          origAppender.update(config: appender.config)
          appenders[appender.name] = origAppender
        }
        else if let base = try? AppenderFactory.create(type: appender.type, name:appender.name, config: appender.config) {
          appenders[appender.name] = base
        }
      }
      
      //Loggers
      var loggers = [Logger]()
      for logger in config.loggers {
        if let appender = appenders[logger.appenderRef] {
          let logger = Logger(key: logger.name ?? "",
                              severity: Severity(name: logger.level),
                              callStackSeverity: logger.callStackLevel != nil ? Severity(name: logger.callStackLevel!) : Severity.Off,
                              appender: appender)
          loggers.append(logger)
        }
      }
      
      self.appenders = appenders
      self.loggers = loggers
      NotificationCenter.default.post(name: NotificationName.ConfigChange, object: nil);
    }
  }
}
