//
//  BaseAppender.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 01/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation
typealias Config = [String: Any]
protocol BaseAppender {
  var name: String { get }
  
  init(name: String, config: Config?)
  
  func update(config: Config?)
  
  func push(log: BaseLog)
  
  func flush()
  
  func saveCrash(exception: Exception)
}

