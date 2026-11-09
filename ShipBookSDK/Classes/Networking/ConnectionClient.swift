//
//  HttpRestClient.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//
#if canImport(UIKit)
import Foundation

//HTTP Methods
enum HttpMethod : String {
    case  GET
    case  POST
    case  DELETE
    case  PUT
}

class ResponseData {
  private static let defaultPause: TimeInterval = 60 * 60
  private static let maxPause: TimeInterval = 30 * 24 * 60 * 60

  var response: HTTPURLResponse?
  var ok: Bool = false
  var statusCode: Int = 0
  var data: Data?
  var error: ErrorResponse?
  var retryAfter: Int?
  var pause: TimeInterval? {
    if let retryAfter = retryAfter { return min(TimeInterval(retryAfter), ResponseData.maxPause) }
    return statusCode == 429 ? ResponseData.defaultPause : nil
  }
  
  init(response: HTTPURLResponse?,data: Data?) {
    self.response = response
    if response != nil {
      self.ok = 200...299 ~= response!.statusCode
      self.statusCode = response!.statusCode
    }
    if let data = data {
      self.data = data
      if !ok {
        error = try? ConnectionClient.jsonDecoder.decode(ErrorResponse.self, from:data)
      }
    }
    // HTTP/2 sends header names in lowercase and allHeaderFields is case sensitive in Swift
    let header = response?.allHeaderFields.first { ($0.key as? String)?.lowercased() == "retry-after" }?.value as? String
    if statusCode >= 400, let seconds = Int(header ?? ""), seconds > 0 {
      retryAfter = seconds
    }
  }
}

class ConnectionClient {
  private init(){
  }
  static let shared = ConnectionClient()
  private static let appIdHeader = "x-shipbook-app-id"
  private static let sdkHeader = "x-shipbook-sdk"
  
  static var BASE_URL = "https://api.shipbook.io/v2/"
  let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter
  }()
  
  static let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.formatted(ConnectionClient.shared.dateFormatter)
    return decoder
  }()
  
  static let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = JSONEncoder.DateEncodingStrategy.formatted(ConnectionClient.shared.dateFormatter)
    return encoder
  }()

  var session: URLSession  = {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 30
    return URLSession(configuration: configuration)
  }()

  func request<T : Encodable>(url: String, data: T?, method: HttpMethod?, completionHandler:@escaping(ResponseData)->Void) -> Void {
    let requestURL = URL(string: ConnectionClient.BASE_URL + url)!
    if SessionManager.shared.paused {
      completionHandler(ResponseData(response: HTTPURLResponse(url: requestURL, statusCode: 429, httpVersion: nil, headerFields: nil), data: nil))
      return
    }
    var urlRequest = URLRequest(url: requestURL)
    if let data = data {
      let jsonData = try? ConnectionClient.jsonEncoder.encode(data)
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = jsonData
    }
    let origData = data //needed for the case that there is needed refreshToken

    urlRequest.httpMethod = method?.rawValue

    if let token = SessionManager.shared.token {
      urlRequest.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
    }
    urlRequest.setValue(SessionManager.shared.appId, forHTTPHeaderField: ConnectionClient.appIdHeader)
    urlRequest.setValue("ios/" + shipBookSDKVersion, forHTTPHeaderField: ConnectionClient.sdkHeader)
    
    session.dataTask(with: urlRequest as URLRequest) { (data, response, error) -> Void in
      let response = ResponseData(response: response as? HTTPURLResponse, data: data)
      if let pause = response.pause {
        SessionManager.shared.pause(for: pause)
        let retryAfter = response.retryAfter.map { "with Retry-After \($0)" } ?? "without Retry-After"
        InnerLog.w("Shipbook paused until \(SessionManager.shared.pausedUntil.toISO8601Format()): the server answered \(response.statusCode) \(retryAfter)")
      }
      if !response.ok && response.statusCode == 401 && response.error?.name == "TokenExpired"  { // call refresh token
        SessionManager.shared.refreshToken() {(succeeded) in
          guard succeeded else {
            completionHandler(response) //didn't succeed to refreshToken therefor passing it to handler
            return
          }
          self.request(url: url, data: origData, method: method, completionHandler: completionHandler)
        }
      }
      else {
        completionHandler(response);
      }
    }.resume()
  }
}
#endif
