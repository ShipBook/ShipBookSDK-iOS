//
//  BaseEvent.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation
class BaseEvent: BaseLog {
  override init(type: String) {
    super.init(type: type)
  }
  
  required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
  }

//  // TODO: the encoding isn't working
//  override func encode(to encoder: Encoder) throws {
//    try super.encode(to: encoder)
//  }
}
