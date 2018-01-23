//
//  AppenderFactory.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 07/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation



struct AppenderFactory {
  struct FactoryError : Error {
  }
  
  static func create(type: String, name: String, config: Config?) throws -> BaseAppender {
    switch type {
    case "ConsoleAppender":
      return ConsoleAppender(name: name, config: config)
    case "OsLogAppender":
      return OsLogAppender(name: name, config: config)
    case "SLCloudAppender", "SBCloudAppender": // SLCloudAppender for backward compatibility
      return SBCloudAppender(name: name, config: config)
      
    default:
      throw FactoryError()
    }
  }
}
