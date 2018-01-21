//
//  Encodable+String.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 21/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

extension Encodable {
  func toJsonString() throws  -> String? {
    return try String(data:toJsonData(), encoding: .utf8)
  }
  
  func toJsonData() throws -> Data {
    return try JSONEncoder().encode(self)
  }
}
