//
//  ActionEvent.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class ActionEvent: BaseEvent {
  var action: String
  var sender: String?
  var senderTitle: String?
  var target: String?
  
  init(action: String, sender: String?, senderTitle: String?, target: String?) {
    self.action = action
    self.sender = sender
    self.senderTitle = senderTitle
    self.target = target
    super.init(type: "actionEvent")
  }
  
  enum CodingKeys: String, CodingKey {
    case action
    case sender
    case senderTitle
    case target
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.action = try container.decode(String.self, forKey: .action)
    self.sender = try container.decodeIfPresent(String.self, forKey: .sender)
    self.senderTitle = try container.decodeIfPresent(String.self, forKey: .senderTitle)
    self.target = try container.decodeIfPresent(String.self, forKey: .target)
    try super.init(from: decoder)
  }

  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(action, forKey: .action)
    try container.encodeIfPresent(sender, forKey: .sender)
    try container.encodeIfPresent(senderTitle, forKey: .senderTitle)
    try container.encodeIfPresent(target, forKey: .target)
    try super.encode(to: encoder)
  }
}
