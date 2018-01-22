//
//  NotificationNames.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 09/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

struct NotificationName {
  static let ConfigChange = Notification.Name(rawValue: "io.shipbook.ShipBookSDK.config")
  static let Connected = Notification.Name(rawValue: "io.shipbook.ShipBookSDK.connected")
  static let UserChange = Notification.Name(rawValue: "io.shipbook.ShipBookSDK.user")
}
