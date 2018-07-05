//
//  BaseLog.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 20/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

class BaseLog: Codable  {
  static var dispatchQueue = DispatchQueue(label: "io.shipbook.counter")
  static var count: Int = 0
  
  var time: Date
  var orderId: Int
  var threadInfo: ThreadInfo
  var type: String
  
  init(type: String) {
    self.type = type
    time = Date()
    threadInfo = ThreadInfo()
    self.orderId =  0
    BaseLog.dispatchQueue.sync {
      BaseLog.count += 1
      self.orderId = BaseLog.count
    }
  }
  
  enum BaseCodingKeys: String, CodingKey {
    case time
    case orderId
    case threadInfo
    case type
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: BaseCodingKeys.self)
    let time = try container.decode(String.self, forKey: .time)
    self.time = time.toDate()
    self.orderId = try container.decode(Int.self, forKey: .orderId)
    self.threadInfo = try container.decode(ThreadInfo.self, forKey: .threadInfo)
    self.type = try container.decode(String.self, forKey: .type)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: BaseCodingKeys.self)
    try container.encode(time.toISO8601Format(), forKey: .time)
    try container.encode(orderId, forKey: .orderId)
    try container.encode(threadInfo, forKey: .threadInfo)
    try container.encode(type, forKey: .type)
  }

}

struct ThreadInfo: Codable {
  var isMain: Bool
  var queueLabel: String
  var threadName: String
  var threadId: UInt64
  init (){
    isMain = Thread.current.isMainThread
    queueLabel = DispatchQueue.currentLabel
    threadName = Thread.current.name ?? ""
    self.threadId = Thread.threadId
  }
}

extension ThreadInfo: Equatable {}
func ==(lhs: ThreadInfo, rhs: ThreadInfo) -> Bool {
  return lhs.isMain == rhs.isMain &&
    lhs.queueLabel == rhs.queueLabel &&
    lhs.threadName == rhs.threadName &&
    lhs.threadId == rhs.threadId
}

extension BaseLog: Equatable {}

func ==(lhs: BaseLog, rhs: BaseLog) -> Bool {
  return lhs.time.toISO8601Format() == rhs.time.toISO8601Format() &&
    lhs.threadInfo == rhs.threadInfo &&
    lhs.type == rhs.type
}


