//
//  SnabbleAPI.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

public struct SnabbleProject {
    public let name: String
    public let jwt: String
    public let weighPrefixes: [String]
    public let currencySymbol: String
    public let decimalDigits: Int

    public init(name: String, jwt: String, weighPrefixes: [String], currencySymbol: String, decimalDigits: Int) {
        self.name = name
        self.jwt = jwt
        self.weighPrefixes = weighPrefixes
        self.currencySymbol = currencySymbol
        self.decimalDigits = decimalDigits
    }
}

/// general config data for using the snabble API.
/// Applications must create the singleton instance and call `setup()` before they make their first API call.
public class APIConfig {
    public static let shared = APIConfig()
    private(set) var project: SnabbleProject
    private(set) var baseUrl: String

    var clientId: String {
        if let id = UserDefaults.standard.string(forKey: "Snabble.api.clientId") {
            return id
        } else {
            let id = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
            UserDefaults.standard.set(id, forKey: "Snabble.api.clientId")
            return id
        }
    }

    private init() {
        self.baseUrl = ""
        self.project = SnabbleProject(name: "none", jwt: "", weighPrefixes: [], currencySymbol: "€", decimalDigits: 2)
    }

    /// initialize the API configuration for the subsequent network calls
    ///
    /// - Parameters:
    ///   - host: either the hostname (e.g. "api.snabble.io") or baseUrl (e.g. "https://api.snabble.io")".
    ///     If a hostname is passed, `https://` will be used as the URL scheme
    ///   - jwt: the JWT that has been assigned your project
    ///
    public func setup(with project: SnabbleProject, using baseUrl: String) {
        self.project = project
        self.baseUrl = baseUrl
    }

    func urlFor(_ url: String) -> URL? {
        return URL(string: self.absoluteUrl(url))
    }

    private func absoluteUrl(_ url: String) -> String {
        if url.hasPrefix("/") {
            return self.baseUrl + url
        } else {
            return url
        }
    }


}

enum HTTPRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
}

struct SnabbleAPI {

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - json: if true, add "application/json" as the "Accept" and "Content-Type" HTTP Headers
    ///   - parameters: the query parameters to append to the URL
    ///   - timeout: the timeout for the HTTP request (0 for no timeout)
    /// - Returns: the URLRequest
    static func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, parameters: [String: String]? = nil, timeout: TimeInterval) -> URLRequest? {
        guard
            let url = urlString(url, parameters),
            let fullUrl = APIConfig.shared.urlFor(url) else {
            return nil
        }

        return request(method, fullUrl, json: json, timeout: timeout)
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - body: the JSON data to send as the HTTP body
    ///   - timeout: the timeout for the HTTP request (0 for no timeout)
    /// - Returns: the URLRequest
    static func request(_ method: HTTPRequestMethod, _ url: String, body: Data, timeout: TimeInterval) -> URLRequest? {
        guard let url = APIConfig.shared.urlFor(url) else {
            return nil
        }
        var urlRequest = request(method, url, timeout: timeout)
        urlRequest.httpBody = body
        return urlRequest
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - body: the JSON object to send as the HTTP body
    ///   - timeout: the timeout for the HTTP request (0 for no timeout)
    /// - Returns: the URLRequest
    static func request<T: Encodable>(_ method: HTTPRequestMethod, _ url: String, body: T, timeout: TimeInterval) -> URLRequest? {
        guard let url = APIConfig.shared.urlFor(url) else {
            return nil
        }
        do {
            var urlRequest = request(method, url, timeout: timeout)
            urlRequest.httpBody = try JSONEncoder().encode(body)
            return urlRequest
        } catch {
            NSLog("error serializing request body: \(error)")
            return nil
        }
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the absolute URL to use
    ///   - json: if true, add "application/json" as the "Accept" and "Content-Type" HTTP Headers
    ///   - timeout: the timeout for the HTTP request (0 for no timeout)
    /// - Returns: the URLRequest
    static func request(_ method: HTTPRequestMethod, _ url: URL, json: Bool = true, timeout: TimeInterval) -> URLRequest {
        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = method.rawValue
        urlRequest.addValue(APIConfig.shared.project.jwt, forHTTPHeaderField: "Client-Token")
        urlRequest.addValue(APIConfig.shared.clientId, forHTTPHeaderField: "Client-Id")

        if timeout > 0 {
            urlRequest.timeoutInterval = timeout
        }

        if json {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - retryCount: how often the request should be retried on failure
    ///   - pauseTime: how long (in seconds) to wait after a failed request. This value is doubled for each retry after the first.
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - obj: the parsed result object, or nil if an error occured
    static func retry<T: Decodable>(_ retryCount: Int, _ pauseTime: TimeInterval, _ request: URLRequest, _ completion: @escaping (_ obj: T?) -> () ) {
        perform(request) { (obj: T?) in
            if obj != nil {
                completion(obj)
            } else if retryCount > 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseTime) {
                    retry(retryCount - 1, pauseTime * 2, request, completion)
                }
            } else {
                completion(nil)
            }
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - obj: the parsed result object, or nil if an error occured
    @discardableResult
    static func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ obj: T?) -> () ) -> URLSessionDataTask {
        return perform(request, returnRaw: false) { (_ obj: T?, _) in
            completion(obj)
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - returnRaw: indicates whether the raw JSON data should be returned along with the decoded data
    ///   - completion: called on the main thread when the result is available.
    ///   - obj: the parsed result object, or nil if an error occured
    ///   - raw: the JSON structure returned by the server, or nil if an error occurred
    @discardableResult
    static func perform<T: Decodable>(_ request: URLRequest, returnRaw: Bool, _ completion: @escaping (_ obj: T?, _ raw: [String: Any]?) -> () ) -> URLSessionDataTask {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request) { data, response, error in
            let url = request.url?.absoluteString ?? "n/a"
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 || response.statusCode == 201
            else {
                NSLog("error getting response from \(url): \(String(describing: error))")
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
                return
            }

            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                var json: [String: Any]? = nil
                if returnRaw {
                    json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                }
                DispatchQueue.main.async {
                    completion(result, json)
                }
            } catch {
                NSLog("error parsing response from \(url): \(error)")
            }
        }
        task.resume()
        return task
    }

    private static func urlString(_ url: String, _ parameters: [String: String]?) -> String? {
        let queryItems = parameters?.map { (k, v) in
            URLQueryItem(name: k, value: v)
        }

        guard var urlComponents = URLComponents(string: url) else {
            return nil
        }
        if urlComponents.queryItems == nil {
            urlComponents.queryItems = queryItems
        } else {
            urlComponents.queryItems?.append(contentsOf: queryItems ?? [])
        }

        return urlComponents.url?.absoluteString
    }

}
