//
//  EventManager.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//
#if canImport(UIKit)
import Foundation
import UIKit

class EventManager {
  static let shared = EventManager()
  var hasViewController = false
  var hasAction = false
  
  private init() {}
  
  func enableViewController() {
    guard !hasViewController else { return } //just extra security but it should never be called
    hasViewController = true
    
    let viewController = UIViewController.self
    swizzle(cls:viewController, original: #selector(viewController.viewDidLoad), swizzled: #selector(viewController.proj_viewDidLoad))
    swizzle(cls:viewController, original: #selector(viewController.viewWillAppear(_:)), swizzled: #selector(viewController.proj_viewWillAppear(_:)))
    swizzle(cls:viewController, original: #selector(viewController.viewDidAppear(_:)), swizzled: #selector(viewController.proj_viewDidAppear(_:)))
    swizzle(cls:viewController, original: #selector(viewController.viewWillDisappear(_:)), swizzled: #selector(viewController.proj_viewWillDisappear(_:)))
    swizzle(cls:viewController, original: #selector(viewController.viewDidDisappear(_:)), swizzled: #selector(viewController.proj_viewDidDisappear(_:)))
  }

  func enableAction() {
    guard !hasAction else { return } //just extra security but it should never be called
    hasAction = true
    
    let application = UIApplication.self
    swizzle(cls:application, original: #selector(application.sendAction(_:to:from:for:)), swizzled: #selector(application.proj_sendAction(_:to:from:for:)))
  }
  
  func enableApp() {
    let block = {(notification: Notification) in
      let application = notification.object as! UIApplication
  #if os(iOS)
      let event = AppEvent(event:notification.name.rawValue, state:application.applicationState, orientation: application.statusBarOrientation)
  #else
      let event = AppEvent(event:notification.name.rawValue, state:application.applicationState)
  #endif
      LogManager.shared.push(log: event)
    }
    
  #if swift(>=4.2)
    NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil, using: block)
    
    NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: nil, using: block)
    #if os(iOS)
    NotificationCenter.default.addObserver(forName: UIApplication.didChangeStatusBarOrientationNotification, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: nil, using: block)
    #endif
  #else
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidFinishLaunching, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillTerminate, object: nil, queue: nil, using: block)

    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationSignificantTimeChange, object: nil, queue: nil, using: block)
    #if os(iOS)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil, queue: nil, using: block)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillChangeStatusBarOrientation, object: nil, queue: nil, using: block)
    #endif
  #endif
  }
  
  
  
  private func swizzle(cls: AnyClass, original originalSelector: Selector, swizzled swizzledSelector: Selector) {
    let originalMethod = class_getInstanceMethod(cls, originalSelector)
    let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector)
    method_exchangeImplementations(originalMethod!, swizzledMethod!)
  }
}

extension UIViewController {
  var name: String {
    get { return String(reflecting: type(of: self)) }
  }
  
  @objc func proj_viewDidLoad() {
    self.proj_viewDidLoad()
    let vcEvent = ViewControllerEvent(name: self.name, event: "viewDidLoad", title: self.title)
    LogManager.shared.push(log: vcEvent)
  }
  @objc func proj_viewWillAppear(_ animated: Bool) {
    self.proj_viewWillAppear(animated)
    let vcEvent = ViewControllerEvent(name: self.name, event: "viewWillAppear", title: self.title)
    LogManager.shared.push(log: vcEvent)
  }
  
  @objc func proj_viewDidAppear(_ animated: Bool) {
    self.proj_viewDidAppear(animated)
    let vcEvent = ViewControllerEvent(name: self.name, event: "viewDidAppear", title: self.title)
    LogManager.shared.push(log: vcEvent)
  }
  
  @objc func proj_viewWillDisappear(_ animated: Bool) {
    self.proj_viewWillDisappear(animated)
    let vcEvent = ViewControllerEvent(name: self.name, event: "viewWillDisappear", title: self.title)
    LogManager.shared.push(log: vcEvent)
  }
  
  @objc func proj_viewDidDisappear(_ animated: Bool) {
    self.proj_viewDidDisappear(animated)
    let vcEvent = ViewControllerEvent(name: self.name, event: "viewDidDisappear", title: self.title)
    LogManager.shared.push(log: vcEvent)
  }
}


extension UIApplication {
  @objc func proj_sendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) -> Bool {
    let ret = self.proj_sendAction(action, to: target, from: sender, for: event)
    let senderString = sender != nil ? String(reflecting: type(of: sender!)) : nil
    var senderTitle: String?  = nil
    if let sender = sender as? UIButton {
      senderTitle = sender.currentTitle
    }
    let targetString = target != nil ? String(reflecting: type(of: target!)) : nil
    let actionEvent = ActionEvent(action: String(describing: action), sender: senderString, senderTitle: senderTitle, target: targetString)
    LogManager.shared.push(log: actionEvent)
    return ret
  }
}
#endif

