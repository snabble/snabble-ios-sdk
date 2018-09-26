//
//  Project+Network.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

public struct ApiError: Decodable {
    public let error: ErrorResponse
}

public struct ErrorResponse: Decodable {
    public let type: String
    public let message: String
}

enum HTTPRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
}

extension Project {

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - json: if true, add "application/json" as the "Accept" and "Content-Type" HTTP Headers
    ///   - parameters: the query parameters to append to the URL
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    /// - Returns: the URLRequest
    func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, jwtRequired: Bool = true, parameters: [String: String]? = nil, timeout: TimeInterval, completion: @escaping (URLRequest?) -> ()) {
        guard
            let url = SnabbleAPI.urlString(url, parameters),
            let fullUrl = SnabbleAPI.urlFor(url)
            else {
                return completion(nil)
        }

        self.request(method, fullUrl, json, jwtRequired, timeout, completion)
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - json: if true, add "application/json" as the "Accept" and "Content-Type" HTTP Headers
    ///   - queryItems: the query parameters to append to the URL
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    /// - Returns: the URLRequest
    func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, jwtRequired: Bool = true, queryItems: [URLQueryItem], timeout: TimeInterval, completion: @escaping (URLRequest?) -> ()) {
        guard
            let url = SnabbleAPI.urlString(url, queryItems),
            let fullUrl = SnabbleAPI.urlFor(url)
            else {
                return completion(nil)
        }

        self.request(method, fullUrl, json, jwtRequired, timeout, completion)
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - body: the JSON data to send as the HTTP body
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    /// - Returns: the URLRequest
    func request(_ method: HTTPRequestMethod, _ url: String, body: Data, timeout: TimeInterval, completion: @escaping (URLRequest?) -> ()) {
        guard let url = SnabbleAPI.urlFor(url) else {
            return completion(nil)
        }

        self.request(method, url, true, true,  timeout) { request in
            var urlRequest = request
            urlRequest.httpBody = body
            completion(urlRequest)
        }
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - body: the JSON object to send as the HTTP body
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    /// - Returns: the URLRequest
    func request<T: Encodable>(_ method: HTTPRequestMethod, _ url: String, body: T, timeout: TimeInterval = 0, _ completion: @escaping (URLRequest?) -> () ) {
        guard let url = SnabbleAPI.urlFor(url) else {
            return completion(nil)
        }

        self.request(method, url, true, true, timeout) { request in
            do {
                var urlRequest = request
                urlRequest.httpBody = try JSONEncoder().encode(body)
                completion(urlRequest)
            } catch {
                NSLog("error serializing request body: \(error)")
                completion(nil)
            }
        }
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the absolute URL to use
    ///   - json: if true, add "application/json" as the "Accept" and "Content-Type" HTTP Headers
    ///   - jwtRequired: if true, this request required authorization via JWT
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    /// - Returns: the URLRequest
    func request(_ method: HTTPRequestMethod, _ url: URL, _ json: Bool, _ jwtRequired: Bool, _ timeout: TimeInterval, _ completion: @escaping (URLRequest) -> ()) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        if jwtRequired {
            SnabbleAPI.tokenRegistry.getToken(for: self) { token in
                if let token = token {
                    urlRequest.addValue(token, forHTTPHeaderField: "Client-Token")
                }
                self.buildRequest(&urlRequest, timeout, json, completion)
            }
        } else {
            self.buildRequest(&urlRequest, timeout, json, completion)
        }
    }

    func buildRequest(_ request: inout URLRequest, _ timeout: TimeInterval, _ json: Bool, _ completion: @escaping (URLRequest) -> ()) {
        request.addValue(SnabbleAPI.clientId, forHTTPHeaderField: "Client-Id")

        if timeout > 0 {
            request.timeoutInterval = timeout
        }

        if json {
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        completion(request)
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - retryCount: how often the request should be retried on failure
    ///   - pauseTime: how long (in seconds) to wait after a failed request. This value is doubled for each retry after the first.
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - obj: the parsed result object, or nil if an error occured
    ///   - error: if not nil, contains the error response from the backend
    func retry<T: Decodable>(_ retryCount: Int, _ pauseTime: TimeInterval, _ request: URLRequest, _ completion: @escaping (_ obj: T?, _ error: ApiError?) -> () ) {
        perform(request) { (obj: T?, error) in
            if obj != nil {
                completion(obj, nil)
            } else if retryCount > 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseTime) {
                    self.retry(retryCount - 1, pauseTime * 2, request, completion)
                }
            } else {
                completion(nil, error)
            }
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - obj: the parsed result object, or nil if an error occured
    ///   - error: if not nil, contains the error response from the backend
    @discardableResult
    func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ obj: T?, _ error: ApiError?) -> () ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: false) { (_ obj: T?, error, json, headers) in
            completion(obj, error)
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - obj: the parsed result object, or nil if an error occured
    ///   - error: if not nil, contains the error response from the backend
    ///   - response: the HTTPURLResponse object
    @discardableResult
    func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ obj: T?, _ error: ApiError?, _ response: HTTPURLResponse?) -> () ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: false) { (_ obj: T?, error, json, response) in
            completion(obj, error, response)
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - returnRaw: indicates whether the raw JSON data should be returned along with the decoded data
    ///   - completion: called on the main thread when the result is available.
    ///   - obj: the parsed result object, or nil if an error occured
    ///   - error: if not nil, contains the error response from the backend
    ///   - raw: the JSON structure returned by the server, or nil if an error occurred
    ///   - response: the HTTPURLResponse object
    @discardableResult
    func perform<T: Decodable>(_ request: URLRequest, returnRaw: Bool, _ completion: @escaping (_ obj: T?, _ error: ApiError?, _ raw: [String: Any]?, _ response: HTTPURLResponse?) -> () ) -> URLSessionDataTask {
        let start = Date.timeIntervalSinceReferenceDate
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request) { rawData, response, error in
            let elapsed = Date.timeIntervalSinceReferenceDate - start
            let url = request.url?.absoluteString ?? "n/a"
            NSLog("get \(url) took \(elapsed)s")
            guard
                let data = rawData,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 || httpResponse.statusCode == 201
                else {
                    NSLog("error getting response from \(url): \(String(describing: error))")
                    var apiError: ApiError?
                    if let data = rawData {
                        do {
                            let error = try JSONDecoder().decode(ApiError.self, from: data)
                            NSLog("error response: \(String(describing: error))")
                            apiError = error
                        }
                        catch {
                            let rawResponse = String(bytes: data, encoding: .utf8)
                            NSLog("failed parsing error response: \(String(describing: rawResponse)) -> \(error)")
                        }
                    }
                    DispatchQueue.main.async {
                        completion(nil, apiError, nil, response as? HTTPURLResponse)
                    }
                    return
            }

            // handle empty response
            if data.count == 0 {
                DispatchQueue.main.async {
                    completion(nil, nil, nil, httpResponse)
                }
                return
            }
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                var json: [String: Any]?
                if returnRaw {
                    json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                }
                DispatchQueue.main.async {
                    completion(result, nil, json, httpResponse)
                }
            } catch {
                NSLog("error parsing response from \(url): \(error)")
                let body = String(bytes: data, encoding: .utf8) ?? ""
                NSLog("raw response body: \(body)")
                DispatchQueue.main.async {
                    completion(nil, nil, nil, httpResponse)
                }
            }
        }
        task.resume()
        return task
    }

}
