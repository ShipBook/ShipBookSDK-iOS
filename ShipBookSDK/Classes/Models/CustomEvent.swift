//
//  CustomEvent.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 07/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class CustomEvent: BaseEvent {
  var event: String
  var params: [String: String]?
  
  init(event: String, params: [String:String]?, type: String = "event") {
    self.event = event
    self.params = params
    super.init(type: type)
  }
  
  enum CodingKeys: String, CodingKey {
    case event
    case params
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.event = try container.decode(String.self, forKey: .event)
    self.params = try container.decodeIfPresent(Dictionary<String, String>.self, forKey: .params)
    try super.init(from: decoder)
  }
  // TODO: the encoding isn't working
  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(event, forKey: .event)
    try container.encodeIfPresent(params, forKey: .params)
    try super.encode(to: encoder)
  }
}
