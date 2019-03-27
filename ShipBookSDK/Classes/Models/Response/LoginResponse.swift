//
//  LoginResp.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © ShipBook Ltd. All rights reserved.
//

import Foundation

struct LoginResponse : Decodable {
  let config: ConfigResponse
  let token: String
  let sessionUrl: String
}
