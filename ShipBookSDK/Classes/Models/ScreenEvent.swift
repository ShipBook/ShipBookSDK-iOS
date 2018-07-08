//
//  ScrennEvent.swift
//  Pods-ShipBookSDK_Example
//
//  Created by Elisha Sterngold on 08/07/2018.
//

import Foundation
//
//  ScreenEvent.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 08/07/2018.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class ScreenEvent: BaseEvent {
  var name: String
  
  init(name: String) {
    self.name = name
    super.init(type: "screenEvent")
  }
  
  enum CodingKeys: String, CodingKey {
    case name
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try super.encode(to: encoder)
  }
}
