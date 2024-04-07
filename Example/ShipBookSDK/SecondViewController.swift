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
    
  @IBAction func raceCondition () {
    let threadCount = 1000

    // Create a concurrent queue
    let queue = DispatchQueue(label: "io.shipbook.logQueue", attributes: .concurrent)

    for i in 1...threadCount {
      queue.async {
        Log.i("The current log for count \(i)")
      }
    }

    // Optionally, you can add a barrier to wait for all logging to complete
    // before the program exits or moves to the next phase
    queue.async(flags: .barrier) {
        print("All logging completed.")
    }
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
