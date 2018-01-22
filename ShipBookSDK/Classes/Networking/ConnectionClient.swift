//
//  HttpRestClient.swift
//  ShipBook
//
//  Created by Elisha Sterngold on 26/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

import Foundation

//HTTP Methods
enum HttpMethod : String {
    case  GET
    case  POST
    case  DELETE
    case  PUT
}

class ResponseData {
  var response: HTTPURLResponse?
  var ok: Bool = false
  var statusCode: Int = 0
  var data: Data?
  var error: ErrorResponse?
  
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
  }
}

class ConnectionClient {
  static var BASE_URL = "https://api.shipbook.io/v1/"
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter
  }()
  
  static let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.formatted(ConnectionClient.dateFormatter)
    return decoder
  }()
  
  static let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = JSONEncoder.DateEncodingStrategy.formatted(ConnectionClient.dateFormatter)
    return encoder
  }()
  
  func request<T : Encodable>(url: String, data: T?, method: HttpMethod?, completionHandler:@escaping(ResponseData)->Void) -> Void {
    var urlRequest = URLRequest(url: URL(string: ConnectionClient.BASE_URL + url)!)
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
    
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 30
    let session = URLSession(configuration: configuration)
    session.dataTask(with: urlRequest as URLRequest) { (data, response, error) -> Void in
      let response = ResponseData(response: response as? HTTPURLResponse, data: data)
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
