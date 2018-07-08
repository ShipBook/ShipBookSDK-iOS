//
//  SecondViewController.swift
//  ShipBookSDK_Example
//
//  Created by Elisha Sterngold on 22/01/2018.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import UIKit
import ShipBookSDK

fileprivate let log = ShipBook.getLogger(SecondViewController.self)
class SecondViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    log.e("this is an error message in SecondViewController")
    log.w("this is a warning message in SecondViewController")
    log.i("this is an info message in SecondViewController")
    log.d("this is a debug message in SecondViewController")
    log.v("this is a verbose message in SecondViewController")
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    ShipBook.screen(name: "SecondViewController")
  }

  @IBAction func back () {
    self.dismiss(animated: false)
  }
}
