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
  var userId = 0
  override func viewDidLoad() {
    super.viewDidLoad()
    log.e("this is an error message in SecondViewController")
    log.w("this is a warning message in SecondViewController")
    log.i("this is an info message in SecondViewController")
    log.d("this is a debug message in SecondViewController")
    log.v("this is a verbose message in SecondViewController")
    ShipBook.flush()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    ShipBook.screen(name: "SecondViewController")
  }

  @IBAction func back () {
    self.dismiss(animated: false)
  }
  
  @IBAction func  crash() {
    log.d("entered crash function")
    let numbers = [0]
    let _ = numbers[1]
  }
  
  @IBAction func changeUser() {

    userId = userId + 1
    ShipBook.registerUser(userId: String(userId))
    print("new user id " + String(userId))
  }
  
  @IBAction func logs() {
    log.i("entered new log with user id: " + String(userId))
  }
  
  @IBAction func logout() {
    ShipBook.logout()
  }
}
