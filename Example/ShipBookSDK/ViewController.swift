//
//  ViewController.swift
//  ShipBookSDK
//
//  Created by Elisha Sterngold on 01/21/2018.
//  Copyright (c) 2018 hipBook Ltd. All rights reserved.
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
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    ShipBook.screen(name: "viewController")
  }
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

}

