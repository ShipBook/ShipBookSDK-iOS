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

  public enum Signal : Int32 {
    case SIGABRT
    case SIGILL
    case SIGSEGV
    case SIGFPE
    case SIGBUS
    case SIGPIPE
    
    
    var name: String {
      switch self {
      case .SIGABRT: return "SIGABRT"
      case .SIGILL: return "SIGILL"
      case .SIGSEGV: return "SIGSEGV"
      case .SIGFPE: return "SIGFPE"
      case .SIGBUS: return "SIGBUS"
      case .SIGPIPE: return "SIGPIPE"
      }
    }
  }
  
  typealias SigactionHandler = @convention(c) (Int32, UnsafeMutablePointer<__siginfo>?, UnsafeMutableRawPointer?) -> Void
  
  let signalHandler: SigactionHandler = { sig, siginfo, p in
    let signalName = String(cString: strsignal(sig))
    let callStackSymbols: [String] = Thread.callStackSymbols
    let signalObj  = Signal(rawValue: sig)
    let exceptionName =  signalObj != nil ? signalObj!.name : "No Name";
    for (_, appender) in LogManager.shared.appenders {
      appender.push(log: Exception(name:exceptionName, reason: signalName, callStackSymbols: callStackSymbols, binaryImages: ExceptionManager.shared.binaryImages))
    }
    signal(sig, SIG_DFL)
  }
  private func createException() {
    NSSetUncaughtExceptionHandler { exception in
      let callStackSymbols: [String] = exception.callStackSymbols
      for (_, appender) in LogManager.shared.appenders {
        appender.push(log: Exception(name: exception.name.rawValue, reason: exception.reason, callStackSymbols: callStackSymbols, binaryImages: ExceptionManager.shared.binaryImages))
      }
    }
    
    var sigAction = sigaction()
    sigAction.sa_flags = SA_SIGINFO|SA_RESETHAND;
    sigAction.__sigaction_u.__sa_sigaction = signalHandler
    
    sigaction(SIGABRT, &sigAction, nil)
    sigaction(SIGILL, &sigAction, nil)
    sigaction(SIGSEGV, &sigAction, nil)
    sigaction(SIGFPE, &sigAction, nil)
    sigaction(SIGBUS, &sigAction, nil)
    sigaction(SIGPIPE, &sigAction, nil)
  }
}
#endif
