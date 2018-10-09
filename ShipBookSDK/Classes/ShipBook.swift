//
//  ShipBook.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

public class ShipBook: NSObject {
  @objc static public func start(appId:String, appKey:String) {
    ShipBook.start(appId: appId, appKey: appKey, url: nil)
  }
  
  
  @objc static public func start(appId:String, appKey:String, url: URL?) { // not using default so that it will work on objc
    SessionManager.shared.login(appId: appId, appKey: appKey, userConfig: url)
  }
  
  @objc static public func enableInnerLog(enable: Bool) {
    InnerLog.enabled = enable
  }

  @objc static public func setConnectionUrl(_ url: String) {
    ConnectionClient.BASE_URL = url
  }

  @objc static public func registerUser(userId: String,
                                  userName: String? = nil,
                                  fullName: String? = nil,
                                  email: String? = nil,
                                  phoneNumber: String? = nil,
                                  additionalInfo: [String: String]? = nil) {
      SessionManager.shared.registerUser(userId: userId,
                                         userName: userName,
                                         fullName: fullName,
                                         email: email,
                                         phoneNumber: phoneNumber,
                                         additionalInfo: additionalInfo)
  }
  
  @objc static public func logout() {
    SessionManager.shared.logout()
  }
  
  static public func getLogger(_ klass: AnyClass) -> Log {
    return Log(klass)
  }
  
  static public func getLogger(_ tag: String) -> Log {
    return Log(tag)
  }
  
  @objc static public func screen(name: String) {
    let event = ScreenEvent(name: name)
    LogManager.shared.push(log: event)
  }
}
