//
//  Severity.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

public enum Severity : Int, Codable {
  case Off = 0
  case Error
  case Warning
  case Info
  case Debug
  case Verbose
  
  public init(name: String) {
    switch name {
    case "Error": self = .Error
    case "Warning": self = .Warning
    case "Info": self = .Info
    case "Debug": self = .Debug
    case "Verbose": self = .Verbose
    default: self = .Off
      
    }
  }
  var name: String {
    switch self {
    case .Error: return "Error"
    case .Warning: return "Warning"
    case .Info: return "Info"
    case .Debug: return "Debug"
    case .Verbose: return "Verbose"
    default: return ""
    }
  }
  
  // Codable functions
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(name: try container.decode(String.self))
  }
  
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.name)
  }
  
}

