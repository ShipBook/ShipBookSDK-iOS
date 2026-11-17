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
  private static let configKey = "config"
  static let pauseKey = "pause"
  private static let maxPause: TimeInterval = 30 * 24 * 60 * 60
  private static let defaultBackOff: TimeInterval = 5 * 60
  private static let maxBackOff: TimeInterval = 60 * 60

  struct Pause: Codable {
    let appId: String
    let sdkVersion: String
    let until: Int64
  }

  private(set) var isInLoginRequest: Bool = false
  // Set when loginSdk got a 4xx — integration is wrong (bad appId/appKey, app deleted, etc.). Retrying won't fix it; suppress further attempts in this process so we don't hammer the server.
  private(set) var loginFailedPermanently: Bool = false
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
  }
  
  static let shared = SessionManager()
  
  func login(appId: String, appKey: String, completion: ((_ sessionUrl: String)->())?){ // should be called in the start of the app. if it would have async then there
                                                               // would be messages it missed
    if appId == self.appId && appKey == self.appKey {
      DispatchQueue.shipBook.async {
        self.loginCompletion = completion ?? self.loginCompletion
        if let sessionUrl = self.sessionUrl { completion?(sessionUrl) }
      }
      return
    }

    var loadedCachedConfig = false
    if let cachedConfig = StorageManager.shared.data(forKey: SessionManager.configKey) {
      do {
        try self.readConfig(data: cachedConfig)
        loadedCachedConfig = true
      }
      catch {
        // A config saved by another SDK version may no longer decode; drop it instead of starting with no config until the next login.
        InnerLog.w("cached config is corrupt, deleting it and falling back to the default config: \(error.localizedDescription)")
        StorageManager.shared.remove(forKey: SessionManager.configKey)
      }
    }
    if !loadedCachedConfig {
      // The built-in config is a constant of this SDK; failing to decode it is a bug to surface, not a state to handle.
      try! self.readConfig(data: Data(config.utf8))
    }

    self.appKey = appKey
    self.appId = appId
    self.loginCompletion = completion
    self.login = Login(appId: appId,
                       appKey: appKey)
    self.loginFailedPermanently = false
    self.token = nil
    self.sessionLink = nil
    self.sessionUrl = nil

    self.pausedUntil = .distantPast
    // a pause further ahead than the cap was saved while the device clock was wrong
    if let data = StorageManager.shared.data(forKey: SessionManager.pauseKey),
       let stored = try? JSONDecoder().decode(Pause.self, from: data),
       stored.appId == appId, stored.sdkVersion == shipBookSDKVersion,
       TimeInterval(stored.until) / 1000 <= Date().timeIntervalSince1970 + SessionManager.maxPause {
      self.pausedUntil = Date(timeIntervalSince1970: TimeInterval(stored.until) / 1000)
    }
    if self.paused {
      InnerLog.w("paused until \(self.pausedUntil.toISO8601Format()) (from an earlier run); nothing will be sent")
    }
    else {
      StorageManager.shared.remove(forKey: SessionManager.pauseKey)
    }
    self.innerLogin()
  }

  func pause(for seconds: Int, status: Int) {
    pausedUntil = Date().addingTimeInterval(min(TimeInterval(seconds), SessionManager.maxPause))
    token = nil
    sessionLink = nil
    sessionUrl = nil
    InnerLog.w("paused until \(pausedUntil.toISO8601Format()): the server answered \(status) with x-shipbook-pause \(seconds)")
    guard let appId = appId else { return }
    let stored = Pause(appId: appId, sdkVersion: shipBookSDKVersion, until: Int64(pausedUntil.timeIntervalSince1970 * 1000))
    StorageManager.shared.set(try! JSONEncoder().encode(stored), forKey: SessionManager.pauseKey)
  }

  func backOff(for retryAfter: Int?, status: Int) {
    backOffUntil = Date().addingTimeInterval(min(retryAfter.map { TimeInterval($0) } ?? SessionManager.defaultBackOff, SessionManager.maxBackOff))
    InnerLog.w("backing off until \(backOffUntil.toISO8601Format()): the server answered \(status)")
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
  
  func readConfig(data: Data) throws {
    let config = try JSONDecoder().decode(ConfigResponse.self, from: data)
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

            // saving the config. need to do an hack because there is no way to encode String:any with encode
            let jsonObject = try JSONSerialization.jsonObject(with: response.data!) as! [String:Any]
            let configData =  try JSONSerialization.data(withJSONObject: jsonObject["config"]!)
            StorageManager.shared.set(configData, forKey: SessionManager.configKey)
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
