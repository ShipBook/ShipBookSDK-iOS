//
//  CodableTests.swift
//  ShipBookTests
//
//  Created by Elisha Sterngold on 05/11/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import XCTest
@testable import ShipBookSDK


class CodableTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testMessage() {
    do {
      let jsonEncoder = JSONEncoder()
      let message = Message(message: "Testing the message", severity: Severity.Info, tag: "tag", function: "function", file: "file", line: 25)
      let jsonData = try jsonEncoder.encode(message)
      let jsonString = String(data: jsonData, encoding: .utf8)
      print("JSON String : " + jsonString!)
      
      let jsonDecoder = JSONDecoder()
      let message2 = try jsonDecoder.decode(Message.self, from: jsonData)
      XCTAssertEqual(message, message2)
      
    } catch {
      XCTFail("shouldn't have an exception")
    }
  }
  
  func testException() {
    do {
      let jsonEncoder = JSONEncoder()
      let exception = Exception(name: "test", reason: "test reason", callStackSymbols: ["row 1","row 2"])
      let jsonData = try jsonEncoder.encode(exception)
      let jsonString = String(data: jsonData, encoding: .utf8)
      print("JSON String : " + jsonString!)
      
      let jsonDecoder = JSONDecoder()
      let exception2 = try jsonDecoder.decode(Exception.self, from: jsonData)
      XCTAssertEqual(exception, exception2)
      
    } catch let error {
      XCTFail(error.localizedDescription)
    }
  }

  func testActionEvent() {
    let jsonEncoder = JSONEncoder()
    let event = ActionEvent(action: "test", sender: "sender", senderTitle: nil, target: nil)
    var jsonData: Data? = nil
    XCTAssertNoThrow(jsonData = try jsonEncoder.encode(event))
    let jsonString = String(data: jsonData!, encoding: .utf8)
    print("JSON String : " + jsonString!)
    
    let jsonDecoder = JSONDecoder()
    var event2: ActionEvent? = nil
    XCTAssertNoThrow(event2 = try jsonDecoder.decode(ActionEvent.self, from: jsonData!))
    XCTAssertEqual(event, event2!)
  }
  
  func testViewControllerEvent() {
    let jsonEncoder = JSONEncoder()
    let event = ViewControllerEvent(name: "test", event: "event", title: nil)
    var jsonData: Data? = nil
    XCTAssertNoThrow(jsonData = try jsonEncoder.encode(event))
    let jsonString = String(data: jsonData!, encoding: .utf8)
    print("JSON String : " + jsonString!)
    
    let jsonDecoder = JSONDecoder()
    var event2: ViewControllerEvent? = nil
    XCTAssertNoThrow(event2 = try jsonDecoder.decode(ViewControllerEvent.self, from: jsonData!))
    XCTAssertEqual(event, event2!)
  }

  func testScreenEvent() {
    let jsonEncoder = JSONEncoder()
    let event = ScreenEvent(name: "test")
    var jsonData: Data? = nil
    XCTAssertNoThrow(jsonData = try jsonEncoder.encode(event))
    let jsonString = String(data: jsonData!, encoding: .utf8)
    print("JSON String : " + jsonString!)
    
    let jsonDecoder = JSONDecoder()
    var event2: ScreenEvent? = nil
    XCTAssertNoThrow(event2 = try jsonDecoder.decode(ScreenEvent.self, from: jsonData!))
    XCTAssertEqual(event, event2!)

  }
  
  func testCustomEvent() {
    let jsonEncoder = JSONEncoder()
    var params = [String: String]()
    params["test1"] = "test"
    params["test2"] = "test2"
    let event = CustomEvent(event: "test", params: params)
    var jsonData: Data? = nil
    XCTAssertNoThrow(jsonData = try jsonEncoder.encode(event))
    let jsonString = String(data: jsonData!, encoding: .utf8)
    print("JSON String : " + jsonString!)

    let jsonDecoder = JSONDecoder()
    var event2: CustomEvent? = nil
    XCTAssertNoThrow(event2 = try jsonDecoder.decode(CustomEvent.self, from: jsonData!))
    XCTAssertEqual(event, event2!)
  }

  func testTimeEvent() {
    let jsonEncoder = JSONEncoder()
    var params = [String: String]()
    params["test1"] = "test"
    params["test2"] = "test2"
    let event = TimeEvent(duration: 5, event: "test", params: params)
    var jsonData: Data? = nil
    XCTAssertNoThrow(jsonData = try jsonEncoder.encode(event))
    let jsonString = String(data: jsonData!, encoding: .utf8)
    print("JSON String : " + jsonString!)
    
    let jsonDecoder = JSONDecoder()
    var event2: TimeEvent? = nil
    XCTAssertNoThrow(event2 = try jsonDecoder.decode(TimeEvent.self, from: jsonData!))
    XCTAssertEqual(event, event2!)
  }

  func testAppStateEvent() {
    let jsonEncoder = JSONEncoder()
    let event = AppEvent(event: "event", state: UIApplication.State.active, orientation: UIInterfaceOrientation.landscapeLeft)
    XCTAssertEqual(event.state, AppEvent.State.active)
    XCTAssertEqual(event.orientation, AppEvent.Orientation.landscapeLeft)
    var jsonData: Data? = nil
    XCTAssertNoThrow(jsonData = try jsonEncoder.encode(event))
    let jsonString = String(data: jsonData!, encoding: .utf8)
    print("JSON String : " + jsonString!)
    
    let jsonDecoder = JSONDecoder()
    var event2: AppEvent? = nil
    XCTAssertNoThrow(event2 = try jsonDecoder.decode(AppEvent.self, from: jsonData!))
    XCTAssertEqual(event, event2!)
  }

  func testLogin() {
    let jsonEncoder = JSONEncoder()
    let login = Login(appId: "idTest", appKey: "keyTest")
    
    var jsonData: Data? = nil
    XCTAssertNoThrow(jsonData = try jsonEncoder.encode(login))
    let jsonString = String(data: jsonData!, encoding: .utf8)
    print("JSON String : " + jsonString!)
    
    let jsonDecoder = JSONDecoder()
    var login2: Login? = nil
    XCTAssertNoThrow(login2 = try jsonDecoder.decode(Login.self, from: jsonData!))
    XCTAssertEqual(login, login2!)
  }
  
  func testUser() {
    let jsonEncoder = JSONEncoder()
    var additionalInfo = [String: String]()
    additionalInfo["test1"] = "test"
    additionalInfo["test2"] = "test2"
    let user = User(userId: "testing",
                    userName: "testName",
                    fullName: "Test Name",
                    email: "test@test.com",
                    phoneNumber: nil,
                    additionalInfo: additionalInfo)
    
    var jsonData: Data? = nil
    XCTAssertNoThrow(jsonData = try jsonEncoder.encode(user))
    let jsonString = String(data: jsonData!, encoding: .utf8)
    print("JSON String : " + jsonString!)

    let jsonDecoder = JSONDecoder()
    var user2: User? = nil
    XCTAssertNoThrow(user2 = try jsonDecoder.decode(User.self, from: jsonData!))
    XCTAssertEqual(user, user2!)
  }
  
  func testSessionLogData() {
    do {
      let jsonEncoder = JSONEncoder()
      let message = Message(message: "Testing the message", severity: Severity.Info, tag: "tag", function: "function", file: "file", line: 25)
      let exception = Exception(name: "test", reason: "test reason")
      let logs : [BaseLog] = [message, exception]
      let user = User(userId: "testing",
                              userName: "testName",
                              fullName: "Test Name",
                              email: "test@test.com",
                              phoneNumber: "0110101001",
                              additionalInfo: [String: String]())

      let sessionLogData = SessionLogData(token: "fdsafsa", login: Login(appId: "idTest", appKey: "keyTest"), logs: logs, user: user)
      
      let jsonData = try jsonEncoder.encode(sessionLogData)
      let jsonString = String(data: jsonData, encoding: .utf8)
      print("JSON String : " + jsonString!)
      
      let jsonDecoder = JSONDecoder()
      let sessionLogData2 = try jsonDecoder.decode(SessionLogData.self, from: jsonData)
      XCTAssertEqual(sessionLogData,sessionLogData2)
      
    } catch let error {
      XCTFail(error.localizedDescription)
    }
  }
  
  func testAppenderResponse(){
    let appenderString = """
    {
      "type" : "ConsoleAppender",
      "name" : "console",
      "config": {
        "pattern" : "test"
      }
    }
    """
    let jsonDecoder = JSONDecoder()
    var appenderResponse : AppenderResponse? = nil
    XCTAssertNoThrow(appenderResponse = try jsonDecoder.decode(AppenderResponse.self, from: appenderString.data(using: String.Encoding.utf8)!))
    XCTAssertEqual(appenderResponse?.name, "console")
    XCTAssertEqual(appenderResponse?.type, "ConsoleAppender")
    XCTAssertNotNil(appenderResponse?.config)
    XCTAssertEqual(appenderResponse?.config?["pattern"] as? String, "test")
    
    
  }
  
  
  //    func testPerformanceExample() {
  //        // This is an example of a performance test case.
  //        self.measure {
  //            // Put the code you want to measure the time of here.
  //        }
  //    }
  
}
