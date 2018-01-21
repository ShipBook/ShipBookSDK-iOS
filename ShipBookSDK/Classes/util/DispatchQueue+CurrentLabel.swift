//
//  DispatchQueue+CurrentLabel.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 02/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

extension DispatchQueue {
  class var currentLabel: String {
    return String(validatingUTF8: __dispatch_queue_get_label(nil))!
  }
}
