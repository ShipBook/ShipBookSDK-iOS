//
//  ShipBook.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

/**
  The main class of the Shipbook SDK - A remote logging platform
*/
public class ShipBook: NSObject {
  /**
    Starts the shipbook SDK should be called in `application(_:didFinishLaunchingWithOptions:)`
   
    - Parameters:
      - appId: The app id. You get it from https://console.shipbook.io.
      - appKey: The app key. You get it from https://console.shipbook.io.

  */
  @objc static public func start(appId:String, appKey:String) {
    ShipBook.start(appId: appId, appKey: appKey, url: nil)
  }
  
  /**
    Starts the shipbook SDK should be called in `application(_:didFinishLaunchingWithOptions:)`
   
    - Parameters:
      - appId: The app id. You get it from https://console.shipbook.io.
      - appKey: The app key. You get it from https://console.shipbook.io.
      - url: The url of the server. By default it goes to the Shipboook production server.
   */
  @objc static public func start(appId:String, appKey:String, url: URL?) { // not using default so that it will work on objc
    SessionManager.shared.login(appId: appId, appKey: appKey, userConfig: url)
  }
  
  /**
    Open the inner log. This function is for in the case that the SDK doesn't work and you need to understand why.
   
    - Parameter enable: if the innerlog should be enabled
  */
  @objc static public func enableInnerLog(enable: Bool) {
    InnerLog.enabled = enable
  }

  /**
    Change the url of the server.
   
    - Parameters:
      - url: The url of the server. By default it goes to the Shipboook production server.
   */

  @objc static public func setConnectionUrl(_ url: String) {
    ConnectionClient.BASE_URL = url
  }

  /**
    Register the user. This is to connect the user to this session.
   
    The best practice is to set registerUser before ShipBook.start. It will also work after this point however, it will require an additional api request.
    - Parameters:
      - userId: The user id in your app/system.
      - userName: The user name in you system. This is the parameter that the user logs in to you app/system.
      - fullName: The full name of the user.
      - email: The email of the user.
      - phoneNumber: The phone number of the user
    - Warning:
      Be sure that you have concent from the user to save this information. In any case you can save only the userId and like
      this will be able to find in the console the logs for this user
  */
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
  
  /**
    Logout the user. This will create after it a new session where the user isn't connected to it.
   */
  @objc static public func logout() {
    SessionManager.shared.logout()
  }
  
  
  /**
    Create a Log class
    - Parameter klass: The class that you want to create the log class with. It will use the class name as tag for the log class.
  */
  static public func getLogger(_ klass: AnyClass) -> Log {
    return Log(klass)
  }

  /**
    Create a Log class
    - Parameter tag: The tag that the log class will use.
  */
  static public func getLogger(_ tag: String) -> Log {
    return Log(tag)
  }
  
  /**
    Entered in a new screen.
   
    This will help you connect the logs to wich screen is open.
    The best practice is to add this code to viewWillAppear in the view controller.
   
    - Parameter name: The name of the new screen.
  */
  @objc static public func screen(name: String) {
    let event = ScreenEvent(name: name)
    LogManager.shared.push(log: event)
  }
}
