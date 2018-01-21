//
//  Data+Write.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 21/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

extension Data {
  func write(append fileURL: URL) throws {
    if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
      defer {
        fileHandle.closeFile()
      }
      fileHandle.seekToEndOfFile()
      fileHandle.write(self)
    }
    else {
      try write(to: fileURL, options: .atomic)
    }
  }
}
