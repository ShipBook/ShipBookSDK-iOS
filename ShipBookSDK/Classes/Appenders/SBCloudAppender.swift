//
//  SLCloudAppender.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 01/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//
#if canImport(UIKit)
import Foundation
import UIKit

class SBCloudAppender: BaseAppender{
  let name: String
  // config variables
  var maxTime: Double = 3
  var maxFileSize: Int = 1048576
  var flushSeverity: Severity = .Verbose
  var flushSize: Int = 1000
  
  // file names
  let fileURL: URL
  let tempFileURL: URL
  let crashFile: URL
  
  // consts/
  let FILE_CLASS_SEPARATOR = ": "
  let NEW_LINE_SEPARATOR = " \n" //there is in purpose a space. In class will always be \\n
  let TOKEN = "token"

  //internal parameters
  private var timer: DispatchSourceTimer?
  private var backgroundObserver: NSObjectProtocol? = nil
  private var connectedObserver: NSObjectProtocol? = nil
  private var userChangeObserver: NSObjectProtocol? = nil
  private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
  
  private var uploadingSavedData = false
  var hasLog = false
  private var flushQueue = [BaseLog]()
  
  required init(name: String, config: Config?) {
    InnerLog.d("init of CloudAppender")
    self.name = name
    let dir = SessionManager.shared.dirURL
    fileURL =  dir.appendingPathComponent("CloudQueue.log")
    tempFileURL =  dir.appendingPathComponent("TempCloudQueue.log")
    crashFile = dir.appendingPathComponent("Crash.log")

    
    //checking if there exists a temp file.
    if FileManager.default.fileExists(atPath: tempFileURL.path) {
      self.concatTmpFile()
    }
    
    //checking if there exist a crash file
    if FileManager.default.fileExists(atPath: crashFile.path) {
      self.concatCrashFile()
    }
    
    update(config: config)
    
    backgroundObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: nil) {[weak self] notification in
        DispatchQueue.shipBook.async {
          InnerLog.d("I'm out of focus!")
          // it will close soon so better send the information
          self?.backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks") {
              // End the task if time expires.
              guard let taskId = self?.backgroundTaskID else {
                  return
              }
              UIApplication.shared.endBackgroundTask(taskId)
              self?.backgroundTaskID = .invalid
          }
                
          // Send the data synchronously.
          self?.send()
          
          // end task
          guard let taskId = self?.backgroundTaskID else {
              return
          }
          UIApplication.shared.endBackgroundTask(taskId)
          self?.backgroundTaskID = .invalid
        }
    }

    connectedObserver = NotificationCenter.default.addObserver(
      forName: NotificationName.Connected,
      object: nil,
      queue: nil) {[weak self] notification in
        DispatchQueue.shipBook.async {
          InnerLog.d("Connected!")
          InnerLog.d("++++++ the current label: " + DispatchQueue.currentLabel)
          self?.send()
        }
    }
    
    userChangeObserver = NotificationCenter.default.addObserver(
      forName: NotificationName.UserChange,
      object: nil,
      queue: nil) {[weak self] notification in
        DispatchQueue.shipBook.async {
          InnerLog.d("user changed")
          if let user = SessionManager.shared.login?.user {
            self?.saveToFile(data: user)
            self?.createTimer()
          }
        }
    }
  }
  
  func update(config: Config?) {
    maxTime = config?["maxTime"] as? NSNumber as? Double  ?? maxTime
    maxFileSize = config?["maxFileSize"] as? Int ?? maxFileSize
    let flushSeverityString = config?["flushSeverity"] as? String
    if let flushSeverityString = flushSeverityString {
      flushSeverity = Severity(name:flushSeverityString)
    }
    flushSize = config?["flushSize"] as? Int ?? flushSize
  }
  
  deinit {
    NotificationCenter.default.removeObserver(backgroundObserver!)
    NotificationCenter.default.removeObserver(connectedObserver!)
    NotificationCenter.default.removeObserver(userChangeObserver!)
    InnerLog.d("deinit of CloudAppender")
  }
  
  func saveToFile(data: Encodable) {
    do {
      if let attr = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
        let fileSize = attr[FileAttributeKey.size] as! UInt64
        if fileSize > maxFileSize {
          removeFile(url: fileURL)
          hasLog = false
        }
      }
      
      if !hasLog {
        if let token = SessionManager.shared.token {
          let line = TOKEN + FILE_CLASS_SEPARATOR + token
          try line.write(append: fileURL, separatedBy: NEW_LINE_SEPARATOR)
        }
        else if let login = SessionManager.shared.login {
          let prefix = String(describing: Login.self) + FILE_CLASS_SEPARATOR
          if let jsonString = try login.toJsonString() {
            let line = prefix.appending(jsonString)
            try line.write(append: fileURL, separatedBy: NEW_LINE_SEPARATOR)
          }
        }
      }
      let prefix = String(describing: type(of: data)) + FILE_CLASS_SEPARATOR
      if let jsonString = try data.toJsonString() {
        let line = prefix.appending(jsonString)
        try line.write(append: fileURL, separatedBy: NEW_LINE_SEPARATOR)
      }
      hasLog = true
    } catch let error {
      InnerLog.e("save to file error: " + error.localizedDescription)
    }
  }
  
  func push(log: BaseLog) {
    DispatchQueue.shipBook.async {
      if let message = log as? Message { self.push(message: message) }
      else if let exception = log as? Exception { self.push(exception: exception) }
      else if let event = log as? BaseEvent { self.push(event: event) }
    }
  }

  func push(message: Message) {
    if flushSeverity.rawValue < message.severity.rawValue {
      flushQueue.append(message)
      if flushQueue.count > flushSize {
        flushQueue.remove(at: 0)
      }
    }
    else { // the info needs to be flushed and saved
      saveFlushQueue()
      saveToFile(data: message)
      createTimer()
    }
  }
  
  func push(event: BaseEvent) {
    flushQueue.append(event)
    if flushQueue.count > flushSize {
      flushQueue.remove(at: 0)
    }
  }

  func push(exception: Exception) {
    saveFlushQueue()
    saveToFile(data: exception) //no timer needed it is the end of this session
  }
  
  func saveFlushQueue() {
    for flushMessage in flushQueue {
      saveToFile(data: flushMessage)
    }
    flushQueue.removeAll()
  }
  
  private func createTimer () {
    if (timer == nil) {
      InnerLog.d("the current max time: " + String(maxTime))
      timer = DispatchSource.makeTimerSource(queue: DispatchQueue.shipBook)
      #if swift(>=4.0)
        timer?.schedule(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(maxTime * 1000)))
      #else
        timer?.scheduleOneshot(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(maxTime * 1000)))
      #endif
      timer?.setEventHandler { [weak self] in
        InnerLog.d("the current label: " + DispatchQueue.currentLabel)
        self?.timer = nil
        self?.send()
      }
      timer?.resume()
    }
  }
  
  func flush() {
    InnerLog.d("flushed logs")
    send()
  }

  private func send() {
    if let timer = timer {
      timer.cancel()
      self.timer = nil;
    }
    
   if uploadingSavedData {
      InnerLog.d("uploading saved data")
      createTimer()
      return
    }
    
    if !Reachability.isConnectedToNetwork() {
      InnerLog.d("not connected to network")
      createTimer()
    }
    
    if !SessionManager.shared.connected {
      InnerLog.d("not connected")
      return
    }
    
    if !FileManager.default.fileExists(atPath: fileURL.path) {
      InnerLog.d("file doesn't exist there are no logs to send")
      return
    }
    
    uploadingSavedData = true
    defer {
      uploadingSavedData = false
    }
    do {
      try? FileManager.default.removeItem(at: tempFileURL) // for to be sure that the move item will happen
      try FileManager.default.moveItem(at: fileURL, to: tempFileURL)
      hasLog = false
      var sessionsData = try loadFromFile(url: tempFileURL)
      guard sessionsData.count > 0 else {
        InnerLog.w("empty session data eventhough loaded from file")
        return
      }
      
      // remove login that is current session and set token
      for i in 0 ... sessionsData.count - 1 {
        if sessionsData[i].login == SessionManager.shared.login {
          sessionsData[i].token = SessionManager.shared.token
          sessionsData[i].login = nil
          break
        }
      }

      // should be with current time and not with the original time that has nothing to do with it
      let currentTime = Date()
      for i in 0 ... sessionsData.count - 1 {
        sessionsData[i].login?.deviceTime = currentTime
      }
      
      ConnectionClient.shared.request(url: "sessions/uploadSavedData", data: sessionsData, method: HttpMethod.POST) { response in
        if response.ok {
          InnerLog.d("sent uploadSavedData")
          self.removeFile(url:self.tempFileURL)
        }
        else {
          if response.statusCode <= 0 {
            InnerLog.i("no internet")
            DispatchQueue.shipBook.async {
              self.concatTmpFile()
            }
          }
          else if (502...504).contains(response.statusCode) {
            InnerLog.i("server is probably down")
            DispatchQueue.shipBook.async {
              self.concatTmpFile()
            }
          }
          else {
            InnerLog.e("error in sending file: " + response.error!.message)
            if let sessionLogData = sessionsData.first(where: { $0.user != nil }) {
              self.saveToFile(data: sessionLogData)
              self.createTimer()
            }
          }
        }
      }
    } catch let error {
      InnerLog.e("error in sending file: " + error.localizedDescription)
      return
    }
  }

  func loadFromFile(url: URL) throws -> [SessionLogData]{
    var sessionsData = [SessionLogData]()
    let fileContent = try String(contentsOfFile: url.path, encoding: .utf8)
    let linesArray = fileContent.components(separatedBy: NEW_LINE_SEPARATOR)
    let messageName = String(describing: Message.self)
    let exceptionName = String(describing: Exception.self)
    let actionEventName = String(describing: ActionEvent.self)
    let screenEventName = String(describing: ScreenEvent.self)
    let vcEventName = String(describing: ViewControllerEvent.self)
    let appStateEventName = String(describing: AppEvent.self)
    let loginName = String(describing: Login.self)
    let userName = String(describing: User.self)
    var sessionLogData : SessionLogData? = nil
    for line in linesArray {
      if let range = line.range(of: ": ") {
        let className = String(line[..<range.lowerBound])
        let classJson = String(line[range.upperBound...])
        switch className {
        case loginName:
          let login = try classJson.decode(json: Login.self)
          if let sessionLogData = sessionLogData {
            sessionsData.append(sessionLogData)
          }
          sessionLogData = SessionLogData()
          sessionLogData!.login = login
        case TOKEN:
          if let sessionLogData = sessionLogData {
            sessionsData.append(sessionLogData)
          }
          sessionLogData = SessionLogData()
          sessionLogData!.token = classJson
        case messageName:
          let message = try classJson.decode(json: Message.self)
          sessionLogData?.logs.append(message)
        case exceptionName:
          let exception = try classJson.decode(json: Exception.self)
          sessionLogData?.logs.append(exception)
        case actionEventName:
          let actionEvent = try classJson.decode(json: ActionEvent.self)
          sessionLogData?.logs.append(actionEvent)
        case screenEventName:
          let screenEvent = try classJson.decode(json: ScreenEvent.self)
          sessionLogData?.logs.append(screenEvent)
        case vcEventName:
          let vcEvent = try classJson.decode(json: ViewControllerEvent.self)
          sessionLogData?.logs.append(vcEvent)
        case appStateEventName:
          let appStateEvent = try classJson.decode(json: AppEvent.self)
          sessionLogData?.logs.append(appStateEvent)
        case userName:
          let user = try classJson.decode(json: User.self)
          sessionLogData?.user = user
        default:
          InnerLog.e("no classname exists")
        }
      }
    }
    if let sessionLogData = sessionLogData {
      sessionsData.append(sessionLogData)
    }
    return sessionsData
  }
  
  func removeFile(url: URL) {
    do {
      try FileManager.default.removeItem(at: url)
    } catch let error {
      InnerLog.e("remove file error: " + error.localizedDescription)
    }
  }
  
  func concatTmpFile() {
    do {
      if FileManager.default.fileExists(atPath: self.fileURL.path) {
        try String(contentsOf: self.fileURL).write(append: self.tempFileURL, separatedBy: self.NEW_LINE_SEPARATOR)
        try FileManager.default.removeItem(at: self.fileURL) // for that the move item will happen
      }
      try FileManager.default.moveItem(at: self.tempFileURL, to: self.fileURL)
    } catch let error {
      InnerLog.e("concatTmpFile error: " + error.localizedDescription)
    }
  }
  
  func concatCrashFile() {
    do {
      try String(contentsOf: self.crashFile).write(append: self.fileURL, separatedBy: self.NEW_LINE_SEPARATOR)
      try FileManager.default.removeItem(at: self.crashFile) // so that it won't be on the next session
    } catch let error {
      InnerLog.e("concatCrashFile error: " + error.localizedDescription)
    }
  }
  
  func saveCrash(exception: Exception) {
    do {
      if let token = SessionManager.shared.token {
        let line = TOKEN + FILE_CLASS_SEPARATOR + token
        try line.write(append: crashFile, separatedBy: NEW_LINE_SEPARATOR)
      }
      else if let login = SessionManager.shared.login {
        let prefix = String(describing: Login.self) + FILE_CLASS_SEPARATOR
        if let jsonString = try login.toJsonString() {
          let line = prefix.appending(jsonString)
          try line.write(append: crashFile, separatedBy: NEW_LINE_SEPARATOR)
        }
      }
      else {
        InnerLog.e("Didn't have token or login therefor can't save crash")
        return;
      }
      let prefix = String(describing: type(of: exception)) + FILE_CLASS_SEPARATOR
      if let jsonString = try exception.toJsonString() {
        let line = prefix.appending(jsonString)
        try line.write(append: crashFile, separatedBy: NEW_LINE_SEPARATOR)
      }
    } catch let error {
      InnerLog.e("save exception file error: " + error.localizedDescription)
    }
  }
}
#endif
