//
//  SnabbleAPI.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

/// general config data for using the snabble API.
/// Applications must call `SnabbleAPI.setup()` with an instance of this struct before they make their first API call.
public struct SnabbleAPIConfig {
    /// the appID assigned by snabble
    public let appId: String
    /// the base URL to use
    public let baseUrl: String
    /// the sectrect assigned by snabble, used to retrieve authorization tokens
    public let secret: String

    /// set this to true if you want to use the `productsByName` method of `ProductDB`
    public var useFTS = false

    /// if the app comes with a zipped seed database, set this to the path in the Bundle
    public var seedDatabase: String?
    /// if the app comes with a zipped seed database, set this to the db revision of the seed
    public var seedRevision: Int64?
    /// if the app comes with a seed metadata JSON, set this to the path in the Bundle
    public var seedMetadata: String?

    public init(appId: String, baseUrl: String, secret: String) {
        self.appId = appId
        self.baseUrl = baseUrl
        self.secret = secret
    }

    public init(appId: String, baseUrl: String, secret: String, useFTS: Bool, seedDatabase: String?, seedRevision: Int64?, seedMetadata: String?) {
        self.appId = appId
        self.baseUrl = baseUrl
        self.secret = secret
        self.useFTS = useFTS
        self.seedDatabase = seedDatabase
        self.seedRevision = seedRevision
        self.seedMetadata = seedMetadata
    }

    static let none = SnabbleAPIConfig(appId: "none", baseUrl: "", secret: "")
}

public struct SnabbleAPI {
    private(set) public static var config = SnabbleAPIConfig.none
    static var metadata = Metadata.none

    public static var projects: [Project] {
        return self.metadata.projects
    }

    public static func setup(_ config: SnabbleAPIConfig, completion: @escaping ()->() ) {
        self.config = config

        if let metadataPath = config.seedMetadata, self.metadata.projects.count == 0 {
            if let metadata = Metadata.readResource(metadataPath) {
                self.metadata = metadata
            }
        }

        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let version = bundleVersion.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? bundleVersion
        let metadataURL = config.baseUrl + "/metadata/app/\(config.appId)/ios/\(version)"

        Metadata.load(from: metadataURL) { metadata in
            if let metadata = metadata {
                self.metadata = metadata
            }
            completion()
        }
    }
}

extension SnabbleAPI {
    static var clientId: String {
        if let id = UserDefaults.standard.string(forKey: "Snabble.api.clientId") {
            return id
        } else {
            let id = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
            UserDefaults.standard.set(id, forKey: "Snabble.api.clientId")
            return id
        }
    }
}

// MARK: - networking stuff

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

extension SnabbleAPI {

    static func urlFor(_ url: String) -> URL? {
        return URL(string: self.absoluteUrl(url))
    }

    private static func absoluteUrl(_ url: String) -> String {
        if url.hasPrefix("/") {
            return self.config.baseUrl + url
        } else {
            return url
        }
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - json: if true, add "application/json" as the "Accept" and "Content-Type" HTTP Headers
    ///   - parameters: the query parameters to append to the URL
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    /// - Returns: the URLRequest
    static func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, jwtRequired: Bool = true, parameters: [String: String]? = nil, timeout: TimeInterval, completion: @escaping (URLRequest?) -> ()) {
        guard
            let url = urlString(url, parameters),
            let fullUrl = SnabbleAPI.urlFor(url)
        else {
            return completion(nil)
        }

        SnabbleAPI.request(method, fullUrl, json, jwtRequired, timeout, completion)
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
    static func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, jwtRequired: Bool = true, queryItems: [URLQueryItem], timeout: TimeInterval, completion: @escaping (URLRequest?) -> ()) {
        guard
            let url = urlString(url, queryItems),
            let fullUrl = SnabbleAPI.urlFor(url)
        else {
            return completion(nil)
        }

        SnabbleAPI.request(method, fullUrl, json, jwtRequired, timeout, completion)
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - body: the JSON data to send as the HTTP body
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    /// - Returns: the URLRequest
    static func request(_ method: HTTPRequestMethod, _ url: String, body: Data, timeout: TimeInterval, completion: @escaping (URLRequest?) -> ()) {
        guard let url = SnabbleAPI.urlFor(url) else {
            return completion(nil)
        }

        SnabbleAPI.request(method, url, true, true,  timeout) { request in
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
    static func request<T: Encodable>(_ method: HTTPRequestMethod, _ url: String, body: T, timeout: TimeInterval = 0, _ completion: @escaping (URLRequest?) -> () ) {
        guard let url = SnabbleAPI.urlFor(url) else {
            return completion(nil)
        }

        SnabbleAPI.request(method, url, true, true, timeout) { request in
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
    static func request(_ method: HTTPRequestMethod, _ url: URL, _ json: Bool, _ jwtRequired: Bool, _ timeout: TimeInterval, _ completion: @escaping (URLRequest) -> ()) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        if jwtRequired {
            #warning("need project here!")
            let project = Project.none
            TokenRegistry.shared.getToken(for: project.id, from: project.links.tokens.href) { token in
                if let token = token {
                    urlRequest.addValue(token, forHTTPHeaderField: "Client-Token")
                }
                SnabbleAPI.buildRequest(&urlRequest, timeout, json, completion)
            }
        } else {
            SnabbleAPI.buildRequest(&urlRequest, timeout, json, completion)
        }
    }

    static func buildRequest(_ request: inout URLRequest, _ timeout: TimeInterval, _ json: Bool, _ completion: @escaping (URLRequest) -> ()) {
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
    static func retry<T: Decodable>(_ retryCount: Int, _ pauseTime: TimeInterval, _ request: URLRequest, _ completion: @escaping (_ obj: T?, _ error: ApiError?) -> () ) {
        perform(request) { (obj: T?, error) in
            if obj != nil {
                completion(obj, nil)
            } else if retryCount > 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseTime) {
                    retry(retryCount - 1, pauseTime * 2, request, completion)
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
    static func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ obj: T?, _ error: ApiError?) -> () ) -> URLSessionDataTask {
        return perform(request, returnRaw: false) { (_ obj: T?, error, json, headers) in
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
    static func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ obj: T?, _ error: ApiError?, _ response: HTTPURLResponse?) -> () ) -> URLSessionDataTask {
        return perform(request, returnRaw: false) { (_ obj: T?, error, json, response) in
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
    static func perform<T: Decodable>(_ request: URLRequest, returnRaw: Bool, _ completion: @escaping (_ obj: T?, _ error: ApiError?, _ raw: [String: Any]?, _ response: HTTPURLResponse?) -> () ) -> URLSessionDataTask {
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

    private static func urlString(_ url: String, _ parameters: [String: String]?) -> String? {
        let queryItems = parameters?.map { (k, v) in
            URLQueryItem(name: k, value: v)
        }
        return urlString(url, queryItems ?? [])
    }

    private static func urlString(_ url: String, _ queryItems: [URLQueryItem]) -> String? {
        guard var urlComponents = URLComponents(string: url) else {
            return nil
        }
        if urlComponents.queryItems == nil {
            urlComponents.queryItems = queryItems
        } else {
            urlComponents.queryItems?.append(contentsOf: queryItems)
        }

        return urlComponents.url?.absoluteString
    }

}

/// run `closure` synchronized using `lock`
func synchronized<T>(_ lock: Any, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}
