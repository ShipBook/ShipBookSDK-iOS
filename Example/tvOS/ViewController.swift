//
//  ViewController.swift
//  tvOS
//
//  Created by Elisha Sterngold on 11/03/2019.
//  Copyright © 2019 ShipBook Ltd. All rights reserved.
//

import UIKit
import ShipBookSDK

fileprivate let log = ShipBook.getLogger(ViewController.self)
class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    log.e("this is an error message")
    log.w("this is a warning message")
    log.i("this is an info message")
    log.d("this is a debug message")
    log.v("this is a verbose message")

  }


}

