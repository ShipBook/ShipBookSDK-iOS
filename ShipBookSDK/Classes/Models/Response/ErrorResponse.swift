//
//  ErrorResponse.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 28/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

struct ErrorResponse : Decodable {
  let name: String
  let message: String
  let status: Int?
}
