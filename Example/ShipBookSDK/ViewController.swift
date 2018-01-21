//
//  ViewController.swift
//  ShipBookSDK
//
//  Created by Elisha Sterngold on 01/21/2018.
//  Copyright (c) 2018 Elisha Sterngold. All rights reserved.
//

import UIKit
import ShipBookSDK

fileprivate let log = ShipBook.getLogger(ViewController.self)
class ViewController: UIViewController {

    override func viewDidLoad() {
      super.viewDidLoad()
      log.e("this is an error message")
      log.w("this is a warning message")
      log.i("this is an info message")
      log.d("this is a debug message")
      log.v("this is a verbose message")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

