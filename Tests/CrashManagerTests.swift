//
//  CrashManagerTests.swift
//  ShipBookTests
//
//  Created by Elisha Sterngold on 20/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import XCTest

@testable import ShipBookSDK

class CrashManagerTests: XCTestCase {
  class CrashRecorder: BaseAppender {
    var name: String
    var crashes: [Exception] = []

    required init(name: String, config: Config?) {
      self.name = name
    }

    func update(config: Config?) {}

    func push(log: BaseLog) {}

    func flush() {}

    func saveCrash(exception: Exception) {
      crashes.append(exception)
    }
  }

  private static var siginfoCalls = 0
  private static var siginfoSigno: Int32 = 0
  private static var siginfoContext: UnsafeMutableRawPointer?
  private static var plainCalls = 0
  private static var plainSignal: Int32 = 0

  private static let siginfoHandler: ExceptionManager.SigactionHandler = { sig, info, context in
    siginfoCalls += 1
    siginfoSigno = info?.pointee.si_signo ?? 0
    siginfoContext = context
  }

  private static let plainHandler: @convention(c) (Int32) -> Void = { sig in
    plainCalls += 1
    plainSignal = sig
  }

  private var originalPipeAction = sigaction()
  private var recorder: CrashRecorder!

  override func setUp() {
    super.setUp()
    sigaction(SIGPIPE, nil, &originalPipeAction)
    Self.siginfoCalls = 0
    Self.siginfoSigno = 0
    Self.siginfoContext = nil
    Self.plainCalls = 0
    Self.plainSignal = 0
    recorder = CrashRecorder(name: "crashRecorder", config: nil)
    DispatchQueue.shipBook.sync {
      LogManager.shared.appenders = ["crashRecorder": recorder]
    }
  }

  override func tearDown() {
    sigaction(SIGPIPE, &originalPipeAction, nil)
    DispatchQueue.shipBook.sync {
      LogManager.shared.appenders.removeAll()
    }
    super.tearDown()
  }

  func testChainsToSiginfoHandlerWithItsSignalInfo() {
    var previous = sigaction()
    previous.sa_flags = SA_SIGINFO
    previous.__sigaction_u.__sa_sigaction = Self.siginfoHandler
    sigaction(SIGPIPE, &previous, nil)

    ExceptionManager.shared.installSignalHandlers()
    raise(SIGPIPE)

    XCTAssertEqual(recorder.crashes.map { $0.name }, ["SIGPIPE"])
    XCTAssertEqual(Self.siginfoCalls, 1)
    XCTAssertEqual(Self.siginfoSigno, SIGPIPE)
    XCTAssertNotNil(Self.siginfoContext)
  }

  func testChainsToPlainHandlerWithTheSignal() {
    var previous = sigaction()
    previous.__sigaction_u.__sa_handler = Self.plainHandler
    sigaction(SIGPIPE, &previous, nil)

    ExceptionManager.shared.installSignalHandlers()
    raise(SIGPIPE)

    XCTAssertEqual(recorder.crashes.map { $0.name }, ["SIGPIPE"])
    XCTAssertEqual(Self.plainCalls, 1)
    XCTAssertEqual(Self.plainSignal, SIGPIPE)
  }

  func testLeavesIgnoredSignalIgnored() {
    signal(SIGPIPE, SIG_IGN)

    ExceptionManager.shared.installSignalHandlers()
    raise(SIGPIPE)

    var current = sigaction()
    sigaction(SIGPIPE, nil, &current)
    XCTAssertEqual(unsafeBitCast(current.__sigaction_u, to: Int.self), unsafeBitCast(SIG_IGN, to: Int.self))
    XCTAssertTrue(recorder.crashes.isEmpty)
  }

  func testSecondStartKeepsTheHandlerInstalledAfterTheFirst() {
    ExceptionManager.shared.start()
    var previous = sigaction()
    previous.sa_flags = SA_SIGINFO
    previous.__sigaction_u.__sa_sigaction = Self.siginfoHandler
    sigaction(SIGPIPE, &previous, nil)

    ExceptionManager.shared.start()

    var current = sigaction()
    sigaction(SIGPIPE, nil, &current)
    XCTAssertEqual(unsafeBitCast(current.__sigaction_u, to: Int.self), unsafeBitCast(Self.siginfoHandler, to: Int.self))
  }
}
