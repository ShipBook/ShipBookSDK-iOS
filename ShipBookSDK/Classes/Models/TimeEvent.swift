//
//  TimeEvent.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 23/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class TimeEvent: CustomEvent {
  var duration: Int
  
  init(duration: Int, event: String, params: [String:String]?) {
    self.duration = duration
    super.init(event: event, params: params, type: "timeEvent")
  }
  
  enum TimeCodingKeys: String, CodingKey {
    case duration
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: TimeCodingKeys.self)
    self.duration = try container.decode(Int.self, forKey: .duration)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: TimeCodingKeys.self)
    try container.encode(duration, forKey: .duration)
    try super.encode(to: encoder)
  }
}
