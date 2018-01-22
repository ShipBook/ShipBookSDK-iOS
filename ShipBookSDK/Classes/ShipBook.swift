//
//  ShipBook.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

public class ShipBook {
  static public func start(appId:String, appKey:String, url: URL? = nil) {
    SessionManager.shared.login(appId: appId, appKey: appKey, userConfig: url)
  }
  
  static public func enableInnerLog(enable: Bool) {
    InnerLog.enabled = enable
  }

  static public func setConnectionUrl(_ url: String) {
    ConnectionClient.BASE_URL = url
  }

  static public func registerUser(userId: String,
                                  userName: String? = nil,
                                  email: String? = nil,
                                  phoneNumber: String? = nil,
                                  additionalInfo: [String: String]? = nil) {
    DispatchQueue.shipBook.async {
      SessionManager.shared.registerUser(userId: userId,
                                         userName: userName,
                                         email: email,
                                         phoneNumber: phoneNumber,
                                         additionalInfo: additionalInfo)
    }
  }
  
  static public func logout() {
    DispatchQueue.shipBook.async {
      SessionManager.shared.logout()
    }
  }
  
  static public func getLogger(_ klass: AnyClass) -> Log {
    return Log(klass)
  }
  
  static public func getLogger(_ tag: String) -> Log {
    return Log(tag)
  }
}
