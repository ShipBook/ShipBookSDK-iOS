//
//  ViewControllerEvent.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class ViewControllerEvent: BaseEvent {
  var name: String
  var event: String
  var title: String?
  
  init(name: String, event: String, title: String?) {
    self.name = name
    self.event = event
    self.title = title
    super.init(type: "viewControllerEvent")
  }
  
  enum CodingKeys: String, CodingKey {
    case name
    case event
    case title
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.event = try container.decode(String.self, forKey: .event)
    self.title = try container.decodeIfPresent(String.self, forKey: .title)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(event, forKey: .event)
    try container.encodeIfPresent(title, forKey: .title)
    try super.encode(to: encoder)
  }
}
