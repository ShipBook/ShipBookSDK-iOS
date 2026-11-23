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
  var hasApp = false
  
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
    guard !hasApp else { return } // start with another app reads the config again; a second set of observers would double every event
    hasApp = true

    let block = {(notification: Notification) in
      guard let application = notification.object as? UIApplication else {
        return
      }
  #if os(iOS)
      let event = AppEvent(event:notification.name.rawValue, state:application.applicationState, orientation: application.statusBarOrientation)
  #else
      let event = AppEvent(event:notification.name.rawValue, state:application.applicationState)
  #endif
      LogManager.shared.push(log: event)
    }
    
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
  }
  
  
  
  // No sender means the app walked the responder chain itself (to find or resign the first responder); no user did anything.
  func actionEvent(action: Selector, target: Any?, sender: Any?) -> ActionEvent? {
    guard let sender = sender else { return nil }
    let senderTitle = (sender as? UIButton)?.currentTitle ?? (sender as? UIBarItem)?.title
    let targetString = target != nil ? String(reflecting: type(of: target!)) : nil
    return ActionEvent(action: String(describing: action), sender: String(reflecting: type(of: sender)), senderTitle: senderTitle, target: targetString)
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
    if let actionEvent = EventManager.shared.actionEvent(action: action, target: target, sender: sender) {
      LogManager.shared.push(log: actionEvent)
    }
    return ret
  }
}
#endif

