//
//  Login.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation
import AdSupport
import UIKit

struct Login : Codable {
  let appId: String
  let appKey: String
  let bundleIdentifier: String
  let appName: String
  let udid: String
  let time: Date
  var deviceTime: Date // the device time in the time of the login request
  
  let os: String = "ios"
  let osVersion: String
  let appVersion: String
  let appBuild: String
  let sdkVersion: String
  let sdkBuild: String
  let manufacturer: String = "apple"
  let deviceName: String
  let deviceModel: String
  var advertisementId: String? = nil
  let language: String
  var isDebug: Bool? = nil
  var user: User?
  
  init(appId: String, appKey: String) {
    self.appId = appId
    self.appKey = appKey
    
    udid = UIDevice.current.identifierForVendor!.uuidString
    time = Date()
    deviceTime = time
    bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
    appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
    osVersion = UIDevice.current.systemVersion
    appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    sdkVersion = sdkBundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    sdkBuild = sdkBundle.infoDictionary?["CFBundleVersion"] as? String ?? ""
    deviceName = UIDevice.current.name
    deviceModel = UIDevice.current.modelName
    language = "\(Locale.current.languageCode ?? "")-\(Locale.current.regionCode ?? "")"
  #if DEBUG
    isDebug = true
  #endif
    advertisementId = nil
    if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
      advertisementId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
  }
}

extension Login: Equatable {}

func ==(lhs: Login, rhs: Login) -> Bool {
  return lhs.appId == rhs.appId &&
    lhs.appKey == rhs.appKey &&
    lhs.udid == rhs.udid &&
    lhs.time.toISO8601Format() == rhs.time.toISO8601Format() &&
    lhs.deviceTime.toISO8601Format() == rhs.deviceTime.toISO8601Format() &&
    lhs.os == rhs.os &&
    lhs.osVersion == rhs.osVersion &&
    lhs.appVersion == rhs.appVersion &&
    lhs.appBuild == rhs.appBuild &&
    lhs.sdkVersion == rhs.sdkVersion &&
    lhs.sdkBuild == rhs.sdkBuild &&
    lhs.manufacturer == rhs.manufacturer &&
    lhs.deviceModel == rhs.deviceModel &&
    lhs.deviceName == rhs.deviceName &&
    lhs.language == rhs.language &&
    lhs.advertisementId == rhs.advertisementId
}


