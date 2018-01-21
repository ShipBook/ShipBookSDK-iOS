//
//  String+Write.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 21/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

extension String {
  func write(append url:URL, separatedBy:String) throws {
    try (self + separatedBy).write(append: url)
  }
  
  func write(append url: URL) throws {
    let data = self.data(using: String.Encoding.utf8)!
    try data.write(append: url)
  }
}
