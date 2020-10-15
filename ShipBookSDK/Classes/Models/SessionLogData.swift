//
//  SessionLogData.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 14/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//
#if canImport(UIKit)
import Foundation

struct SessionLogData: Codable{
  var token: String?
  var login: Login?
  var logs: [BaseLog] = [BaseLog]()
  var user: User?
}

extension SessionLogData: Equatable {}

func ==(lhs: SessionLogData, rhs: SessionLogData) -> Bool {
  return lhs.token == rhs.token &&
    lhs.login == rhs.login &&
    lhs.logs == rhs.logs
}
#endif
