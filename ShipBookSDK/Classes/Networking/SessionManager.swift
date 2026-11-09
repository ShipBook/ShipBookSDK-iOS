//
//  SessionManager.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 29/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//
#if canImport(UIKit)
import Foundation

let config = """
{
  "appenders" :
  [{
   "type" : "ConsoleAppender",
   "name" : "console",
   "config" : {
   "pattern" : "$message"
   }
   },
   {
   "type" : "SBCloudAppender",
   "name" : "cloud",
   "config" :
   {
   "maxTime" : 5,
   "flushSeverity" : "Warning"
   }
   }],
  "loggers" :
  [{
   "name" : "",
   "severity" : "Verbose",
   "appenderRef" : "console"
   },
   {
   "name" : "",
   "severity" : "Verbose",
   "appenderRef" : "cloud"
   }]
}
"""

class SessionManager {
  private static let sessionLinkHeader = "x-shipbook-session"
  private static let maxPause: TimeInterval = 30 * 24 * 60 * 60
  private static let defaultBackOff: TimeInterval = 5 * 60
  private static let maxBackOff: TimeInterval = 60 * 60
  private static let innerLogTimeFormatter = ISO8601DateFormatter()

  struct Pause: Codable {
    let appId: String
    let sdkVersion: String
    let until: Int64
  }

  private(set) var isInLoginRequest: Bool = false
  // Set when loginSdk got a 4xx — integration is wrong (bad appId/appKey, app deleted, etc.). Retrying won't fix it; suppress further attempts in this process so we don't hammer the server.
  private(set) var loginFailedPermanently: Bool = false
  let configURL: URL
  let pauseURL: URL
  let dirURL: URL
  var appKey: String?
  var appId: String?
  var token: String?
  var sessionLink: String?
  private var sessionUrl: String?
  var pausedUntil = Date.distantPast
  var backOffUntil = Date.distantPast
  var paused: Bool {
    return pausedUntil > Date()
  }
  var requestsBlocked: Bool {
    return paused || backOffUntil > Date()
  }
  var loginCompletion: ((_ sessionUrl: String)->())?
  
  private var _login: Login?
  var login: Login? {
    get {
      if let user = user { // adding user to the login
        _login?.user = user
      }
      return _login
    }
    set (login) {
      _login = login
    }
  }
  var user: User?
  
  var connected: Bool {
    get {
      if requestsBlocked { return false }
      if token != nil { return true }
      if loginFailedPermanently { return false }
      innerLogin()
      return false
    }
  }
  
  private init(){
  #if os(tvOS)
    let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
  #else
    let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
  #endif
    dirURL = dir!.appendingPathComponent("shipbook")
    configURL =  dirURL.appendingPathComponent("config.json")
    pauseURL = dirURL.appendingPathComponent("pause.json")
  }
  
  static let shared = SessionManager()
  
  func login(appId: String, appKey: String, completion: ((_ sessionUrl: String)->())?, userConfig: URL?){ // should be called in the start of the app. if it would have async then there
                                                               // would be messages it missed
    if appId == self.appId && appKey == self.appKey {
      DispatchQueue.shipBook.async {
        self.loginCompletion = completion ?? self.loginCompletion
        if let sessionUrl = self.sessionUrl { completion?(sessionUrl) }
      }
      return
    }

    if FileManager.default.fileExists(atPath: self.configURL.path) {
      self.readConfig(url: self.configURL)
    }
    else if let url = userConfig {
      self.readConfig(url: url)
    }
    else {
      self.readConfig(url: nil)
      try? FileManager.default.createDirectory(atPath: self.dirURL.path, withIntermediateDirectories: true, attributes: nil)
    }

    self.appKey = appKey
    self.appId = appId
    self.loginCompletion = completion
    self.login = Login(appId: appId,
                       appKey: appKey)
    self.loginFailedPermanently = false

    self.pausedUntil = .distantPast
    // a pause further ahead than the cap was saved while the device clock was wrong
    if let stored = try? JSONDecoder().decode(Pause.self, from: Data(contentsOf: self.pauseURL)),
       stored.appId == appId, stored.sdkVersion == shipBookSDKVersion,
       TimeInterval(stored.until) / 1000 <= Date().timeIntervalSince1970 + SessionManager.maxPause {
      self.pausedUntil = Date(timeIntervalSince1970: TimeInterval(stored.until) / 1000)
    }
    if self.paused {
      InnerLog.w("paused until \(SessionManager.innerLogTimeFormatter.string(from: self.pausedUntil)) (from an earlier run); nothing will be sent")
    }
    else {
      try? FileManager.default.removeItem(at: self.pauseURL)
    }
    self.innerLogin()
  }

  func pause(for seconds: Int, status: Int) {
    pausedUntil = Date().addingTimeInterval(min(TimeInterval(seconds), SessionManager.maxPause))
    token = nil
    sessionLink = nil
    sessionUrl = nil
    InnerLog.w("paused until \(SessionManager.innerLogTimeFormatter.string(from: pausedUntil)): the server answered \(status) with x-shipbook-pause \(seconds)")
    guard let appId = appId else { return }
    let stored = Pause(appId: appId, sdkVersion: shipBookSDKVersion, until: Int64(pausedUntil.timeIntervalSince1970 * 1000))
    try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
    try? JSONEncoder().encode(stored).write(to: pauseURL, options: .atomic)
  }

  func backOff(for retryAfter: Int?, status: Int) {
    backOffUntil = Date().addingTimeInterval(min(retryAfter.map { TimeInterval($0) } ?? SessionManager.defaultBackOff, SessionManager.maxBackOff))
    InnerLog.w("backing off until \(SessionManager.innerLogTimeFormatter.string(from: backOffUntil)): the server answered \(status)")
  }

  func logout() {
    DispatchQueue.shipBook.async {
      self.token = nil
      self.user = nil
      if self.login != nil {
        self.login = Login(appId: self.appId!,
                           appKey: self.appKey!)
      }
      self.innerLogin()
    }
  }
  
  func registerUser(userId: String,
                    userName: String?,
                    fullName: String?,
                    email: String?,
                    phoneNumber: String?,
                    additionalInfo: [String: String]?) {
    self.user = User(userId: userId,
                    userName: userName,
                    fullName: fullName,
                    email: email,
                    phoneNumber: phoneNumber,
                    additionalInfo: additionalInfo)
    if self.login != nil { //it is still not initialized the user was before the start
      DispatchQueue.shipBook.async {
        NotificationCenter.default.post(name: NotificationName.UserChange, object: self)
      }
    }
  }
  
  struct NoDataError: Error {
  }
  
  func readConfig(url: URL?) {
    do {
      let contents = try url != nil ? Data(contentsOf:url!) : Data(config.utf8)
      let config = try JSONDecoder().decode(ConfigResponse.self, from: contents)
      if !(config.exceptionReportDisabled == true) {
        ExceptionManager.shared.start()
      }
      if !(config.eventLoggingDisabled == true) {
        // EventManager.shared.enableViewController() it is bloating the logs
        EventManager.shared.enableAction()
        EventManager.shared.enableApp()
      }
      LogManager.shared.config(config)
    }
    catch {
      InnerLog.e(error.localizedDescription)
    }
  }
  
  private func innerLogin() {
    if !Reachability.isConnectedToNetwork() || isInLoginRequest || appKey == nil || loginFailedPermanently || requestsBlocked { return }
    isInLoginRequest = true
    sessionLink = nil
    sessionUrl = nil
    let url = "auth/loginSdk"

    login?.deviceTime = Date()
    ConnectionClient.shared.request(url: url, data: login, method: HttpMethod.POST) { response in
      DispatchQueue.shipBook.async {
        self.isInLoginRequest = false
        if response.ok {
          do {
            guard response.data != nil else {
              throw NoDataError()
            }
            let login = try ConnectionClient.jsonDecoder.decode(LoginResponse.self, from: response.data!)
            self.token = login.token
            self.sessionLink = login.sessionLink
            self.sessionUrl = login.sessionUrl

            self.loginCompletion?(login.sessionUrl)

            LogManager.shared.config(login.config)
            NotificationCenter.default.post(name: NotificationName.Connected, object: self)

            // saving the config to a file. need to do an hack because there is no way to encode String:any with encode
            let jsonObject = try JSONSerialization.jsonObject(with: response.data!) as! [String:Any]
            let configData =  try JSONSerialization.data(withJSONObject: jsonObject["config"]!)
            try? configData.write(to: self.configURL)
          }
          catch let error {
            InnerLog.e("didn't succeed to decode \(error)")
            if let data = response.data {
              InnerLog.e("the info that was received" + String(data: data, encoding: String.Encoding.utf8)!)
            }
          }

        }
        else if (400...499).contains(response.statusCode) && response.pause == nil && !response.busy {
          // 4xx on loginSdk = integration error (bad appId/appKey, app deleted). Retrying won't help — stop until the app is restarted or logout/login is called.
          self.loginFailedPermanently = true
          InnerLog.e("loginSdk rejected with \(response.statusCode) — check appId/appKey. Will not retry until next app start.")
        }
        else {
          InnerLog.e("the response not ok")
        }
      }
    }
  }
  
  func refreshToken (completionHandler:@escaping(Bool)->()) {
    if requestsBlocked || !Reachability.isConnectedToNetwork() {
      completionHandler(false)
      return
    }
    guard token != nil && appKey != nil else {
      InnerLog.e("the token or appKey are not initialized")
      return
    }
    let refresh = RefreshToken(token: token!, appKey: appKey!)
    isInLoginRequest = true
    self.token = nil
    ConnectionClient.shared.request(url: "auth/refreshSdkToken", data: refresh, method: HttpMethod.POST) { response in
      self.isInLoginRequest = false
      if response.ok {
        guard response.data != nil else {
          InnerLog.e("missing data on refresh — leaving token nil so the next cycle falls back to a fresh loginSdk")
          completionHandler(false)
          return
        }
        let refreshResp = try? ConnectionClient.jsonDecoder.decode(RefreshTokenResponse.self, from: response.data!)
        self.token = refreshResp?.token
        completionHandler(true)
      }
      else if (400...499).contains(response.statusCode) && response.pause == nil && !response.busy {
        // 4xx on refresh = integration error (app deleted, wrong appKey, bad JWT). Same as loginSdk failure — stop retrying until next app start.
        self.loginFailedPermanently = true
        InnerLog.e("refreshSdkToken rejected with \(response.statusCode) — check appId/appKey. Will not retry until next app start.")
        completionHandler(false)
      }
      else {
        // 5xx / network — leave token nil. SBCloudAppender's next send sees connected=false and fires innerLogin (fresh login), which is the right recovery for transient errors.
        InnerLog.e("refreshSdkToken failed (status \(response.statusCode)) — will fall back to fresh login on next cycle")
        completionHandler(false)
      }
    }
  }

  // Empty until login completes and on silenced devices, so callers can always merge it.
  func getSessionHeaders() -> [String: String] {
    guard let sessionLink = sessionLink else { return [:] }
    return [SessionManager.sessionLinkHeader: sessionLink]
  }
}
#endif
