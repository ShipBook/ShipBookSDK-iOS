//
//  String+Decode.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 21/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

extension String {
  func decode<T: Decodable>(json type: T.Type) throws -> T {
    return try JSONDecoder().decode(type, from: self.data(using: String.Encoding.utf8)!)
  }
}
