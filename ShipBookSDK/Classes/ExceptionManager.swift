//
//  CrashManager.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 19/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//
#if canImport(UIKit)
import Foundation
import MachO.dyld

class ExceptionManager {
  static let shared = ExceptionManager()
  let binaryImages: [BinaryImage]?
  func start(exception: Bool = true) {
    if (exception) {
      createException()
    }
  }
  
  private init() {
    print("binary images")
    let c = _dyld_image_count()
    var binaryImages: [BinaryImage] = Array.init()
    for i in 0..<c {
      let imageName = String(cString: _dyld_get_image_name(i))
      let imageNameEnding = URL(fileURLWithPath: imageName).lastPathComponent
      let header = _dyld_get_image_header(i);
      if let header = header {
        let info = NXGetArchInfoFromCpuType(header.pointee.cputype, header.pointee.cpusubtype);
        if let info = info {
          let arch = String(cString:info.pointee.name)
          let startAddress = Int(bitPattern: header)
          binaryImages.append(BinaryImage(startAddress: String(format: "%018p", startAddress), name: imageNameEnding, arch: arch, path: imageName))
        }
      }
    }
    self.binaryImages = binaryImages
  }

  private struct OldSigAction {
      public var __sigaction_u: __sigaction_u /* signal handler */
      public var sa_mask: sigset_t /* signal mask to apply */
      public var sa_flags: Int32 /* see signal options below */
  }
      
  private var oldSignalHandlers = [Signal:OldSigAction]()

  public enum Signal : Int32, CaseIterable {
    case SIGABRT = 6
    case SIGILL = 4
    case SIGSEGV = 11
    case SIGFPE = 8
    case SIGBUS = 10
    case SIGPIPE = 13
    case SIGTRAP = 5
    
    
    var name: String {
      switch self {
      case .SIGABRT: return "SIGABRT"
      case .SIGILL: return "SIGILL"
      case .SIGSEGV: return "SIGSEGV"
      case .SIGFPE: return "SIGFPE"
      case .SIGBUS: return "SIGBUS"
      case .SIGPIPE: return "SIGPIPE"
      case .SIGTRAP: return "SIGTRAP"
      }
    }
  }
  
  typealias SigactionHandler = @convention(c) (Int32, UnsafeMutablePointer<__siginfo>?, UnsafeMutableRawPointer?) -> Void
  
  let signalHandler: SigactionHandler = { sig, siginfo, p in
    let signalName = String(cString: strsignal(sig))
    let callStackSymbols: [String] = Thread.callStackSymbols
    let signalObj  = Signal(rawValue: sig)
    let exceptionName =  signalObj != nil ? signalObj!.name : "No Name";
    let exception = Exception(name:exceptionName, reason: signalName, callStackSymbols: callStackSymbols, binaryImages: ExceptionManager.shared.binaryImages)
    let appenders = LogManager.shared.appenders //copying so that it can be changed in the middle
    for (_, appender) in appenders {
      appender.saveCrash(exception: exception)
    }

    if let signal = Signal(rawValue: sig), let oldHandler = ExceptionManager.shared.oldSignalHandlers[signal] {
        if (Int32(oldHandler.sa_mask) & SA_SIGINFO) == 0 {
            oldHandler.__sigaction_u.__sa_handler(sig)
        } else {
            oldHandler.__sigaction_u.__sa_sigaction(sig,siginfo,p)
        }
    } else {
        signal(sig, SIG_DFL)
    }
  }
  
  var oldExceptionHandler : (@convention(c) (NSException) -> Void)? = nil
  private func createException() {
    oldExceptionHandler = NSGetUncaughtExceptionHandler()
    NSSetUncaughtExceptionHandler { exception in
      let callStackSymbols: [String] = exception.callStackSymbols
      let appenders = LogManager.shared.appenders //copying so that it can be changed in the middle
      let exc = Exception(name: exception.name.rawValue, reason: exception.reason, callStackSymbols: callStackSymbols, binaryImages: ExceptionManager.shared.binaryImages)
      for (_, appender) in appenders {
        appender.saveCrash(exception: exc)
      }
      if let oldExcHandler = ExceptionManager.shared.oldExceptionHandler {
        oldExcHandler(exception)
      }
    }
    
    var sigAction = sigaction()
    sigAction.sa_flags = SA_SIGINFO|SA_RESETHAND;
    sigAction.__sigaction_u.__sa_sigaction = signalHandler
    
    var old = sigaction()
    for sig in Signal.allCases {
      sigaction(sig.rawValue, &sigAction, &old)
      if old.sa_flags != 0 || old.sa_mask != 0 || old.__sigaction_u.__sa_sigaction != nil || old.__sigaction_u.__sa_handler != nil {
        let convertedOld = OldSigAction(__sigaction_u: old.__sigaction_u, sa_mask: old.sa_mask, sa_flags: old.sa_flags)
        oldSignalHandlers[sig] = convertedOld
      }
    }
  }
}
#endif
