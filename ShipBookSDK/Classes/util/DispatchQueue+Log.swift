//
//  DispatchQueue+Log.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

fileprivate let shipbookQueue = DispatchQueue(label: "io.shipbook.ShipBookSDK")
fileprivate let syncAppenderQueue = DispatchQueue(label: "io.shipbook.syncAppender")
extension DispatchQueue {
  class var shipBook: DispatchQueue {
    return shipbookQueue
  }
  
  class var syncAppender: DispatchQueue {
    return syncAppenderQueue
  }
}
