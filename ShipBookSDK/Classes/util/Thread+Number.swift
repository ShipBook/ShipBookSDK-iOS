//
//  Thread+Number.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

extension Thread {
  class var threadId: UInt64 {
    var threadId: UInt64 = 0
    pthread_threadid_np(nil, &threadId)
    return threadId
  }
}
