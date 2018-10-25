//
//  Severity.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

/// enum of severity
public enum Severity : Int, Codable {
  /// Severity off
  case Off = 0
  /// Error severity
  case Error
  /// Warning severity
  case Warning
  /// Info severity
  case Info
  /// Debug severity
  case Debug
  /// Verbose severity
  case Verbose
  
  init(name: String) {
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
  /// init decoder
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(name: try container.decode(String.self))
  }
  
  /// encode
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.name)
  }
}

