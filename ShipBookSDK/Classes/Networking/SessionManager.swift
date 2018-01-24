//
//  SessionManager.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 29/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

let sdkBundle = Bundle(for: SessionManager.self)
class SessionManager {
  
  private var isInLoginRequest: Bool = false
  let configURL: URL
  var appId: String?
  var appKey: String?
  var token: String?
  var login: Login?
  
  var connected: Bool {
    get {
      if token != nil { return true }
      innerLogin()
      return false
    }
  }
  
  private init(){
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    configURL =  dir!.appendingPathComponent("config.json")
  }
  
  static let shared = SessionManager()
  
  func login(appId: String, appKey: String, userConfig: URL?){
    DispatchQueue.shipBook.async {
      if FileManager.default.fileExists(atPath: self.configURL.path) {
        self.readConfig(url: self.configURL)
      }
      else if let url = userConfig {
        self.readConfig(url: url)
      }
      else if let filepath = sdkBundle.path(forResource: "ShipBookSDK.bundle/config", ofType: "json")  {
        let url = URL(fileURLWithPath: filepath)
        self.readConfig(url: url)
      }
      else {
        InnerLog.e("there was a problem with initialization")
      }

      self.appId = appId
      self.appKey = appKey

      self.login = Login(appId: appId,
                    appKey: appKey)
      
      self.innerLogin()
    }
  }
  
  func logout() {
    DispatchQueue.shipBook.async {
      self.token = nil
      self.login = nil
    }
  }
  
  func registerUser(userId: String,
                    userName: String?,
                    fullName: String?,
                    email: String?,
                    phoneNumber: String?,
                    additionalInfo: [String: String]?) {
    DispatchQueue.shipBook.async {
      let user = User(userId: userId,
                      userName: userName,
                      fullName: fullName,
                      email: email,
                      phoneNumber: phoneNumber,
                      additionalInfo: additionalInfo)
      self.login?.user = user
      NotificationCenter.default.post(name: NotificationName.UserChange, object: self)
    }
  }
  
  struct NoDataError: Error {
  }
  
  func readConfig(url: URL) {
    do {
      let contents = try Data(contentsOf:url)
      let config = try JSONDecoder().decode(ConfigResponse.self, from: contents)
      if !(config.crashReportDisabled == true) {
        CrashManager.shared.start()
      }
      if !(config.eventLoggingDisabled == true) {
        EventManager.shared.enableViewController()
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
    if !Reachability.isConnectedToNetwork() || isInLoginRequest || appId == nil { return }
    isInLoginRequest = true
    let url = "auth/loginSdk"
    
    let client = ConnectionClient()
    login?.deviceTime = Date()
    client.request(url: url, data: login, method: HttpMethod.POST) { response in
      DispatchQueue.shipBook.async {
        self.isInLoginRequest = false
        if response.ok {
          do {
            guard response.data != nil else {
              throw NoDataError()
            }
            let login = try ConnectionClient.jsonDecoder.decode(LoginResponse.self, from: response.data!)
            self.token = login.token
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
        else {
          InnerLog.e("the response not ok")
        }
      }
    }
  }
  
  func refreshToken (completionHandler:@escaping(Bool)->()) {
    if !Reachability.isConnectedToNetwork() {
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
    let client = ConnectionClient()
    client.request(url: "auth/refreshSdkToken", data: refresh, method: HttpMethod.POST) { response in
      self.isInLoginRequest = false
      if response.ok {
        guard response.data != nil else {
          InnerLog.e("missing data")
          return
        }
        let refreshResp = try? ConnectionClient.jsonDecoder.decode(RefreshTokenResponse.self, from: response.data!)
        self.token = refreshResp?.token
        completionHandler(true)
      }
      else {
        completionHandler(false)
      }
    }
  }
}
