//
//  Project+Network.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

// #if swift(<5.0)
/// Implement a trivial version of `Result` when compiling in Swift 4.2 mode
public enum Result<Success, Failure: Swift.Error> {
    case success(Success)
    case failure(Failure)

    public func get() throws -> Success {
        switch self {
        case .success(let success): return success
        case .failure(let failure): throw failure
        }
    }
}
// #endif

public struct SnabbleError: Decodable, Error {
    public let error: ErrorResponse

    static let unknown = SnabbleError(error: ErrorResponse("unknown"))
    static let empty = SnabbleError(error: ErrorResponse("empty"))
    static let invalid = SnabbleError(error: ErrorResponse("invalid"))
    static let noRequest = SnabbleError(error: ErrorResponse("no request"))
    static let notFound = SnabbleError(error: ErrorResponse("not found"))

    static let noPaymentAvailable = SnabbleError(error: ErrorResponse("no payment method available"))
}

public enum ErrorResponseType: String {
    case unknown

    // checkout errors
    case shopNotFound = "shop_not_found"
    case badShopId = "bad_shop_id"
    case noAvailableMethod = "no_available_method"
    case invalidCartItem = "invalid_cart_item"
}

extension ErrorResponseType: UnknownCaseRepresentable {
    public static let unknownCase = ErrorResponseType.unknown
}

public struct ErrorResponse: Decodable {
    public let rawType: String
    public let details: [ErrorDetail]?

    enum CodingKeys: String, CodingKey {
        case rawType = "type"
        case details
    }

    init(_ type: String) {
        self.rawType = type
        self.details = nil
    }

    var type: ErrorResponseType {
        return ErrorResponseType(rawValue: self.rawType)
    }
}

public enum ErrorDetailType: String {
    case unknown

    // invalidCartItem details
    case saleStop = "sale_stop"
    case productNotFound = "product_not_found"
}

extension ErrorDetailType: UnknownCaseRepresentable {
    public static let unknownCase = ErrorDetailType.unknown
}

public struct ErrorDetail: Decodable {
    public let rawType: String
    public let message: String?
    public let sku: String?

    enum CodingKeys: String, CodingKey {
        case rawType = "type"
        case message
        case sku
    }

    var type: ErrorDetailType {
        return ErrorDetailType(rawValue: self.rawType)
    }
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
                self.logError("error serializing request body: \(error)")
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
    ///   - jwtRequired: if true, this request requires authorization via JWT
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
        if let userAgent = Project.userAgent {
            request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        }

        if timeout > 0 {
            request.timeoutInterval = timeout
        }

        if json {
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        completion(request)
    }

    internal static let userAgent: String? = {
        guard
            let bundleDict = Bundle.main.infoDictionary,
            let appName = bundleDict["CFBundleName"] as? String,
            let appVersion = bundleDict["CFBundleShortVersionString"] as? String,
            let appBuild = bundleDict["CFBundleVersion"] as? String
        else {
            return nil
        }

        let appDescriptor = appName + "/" + appVersion + "(" + appBuild + ")"

        let osDescriptor = "iOS/" + UIDevice.current.systemVersion

        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let hardwareString = String(cString: machine)

        return appDescriptor + " " + osDescriptor + " (" + hardwareString + ") SDK/\(APIVersion.version)"
    }()

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - retryCount: how often the request should be retried on failure
    ///   - pauseTime: how long (in seconds) to wait after a failed request. This value is doubled for each retry after the first.
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - result: the parsed result object or error
    func retry<T: Decodable>(_ retryCount: Int, _ pauseTime: TimeInterval, _ request: URLRequest, _ completion: @escaping (_ result: Result<T, SnabbleError>) -> () ) {
        perform(request) { (result: Result<T, SnabbleError>) in
            switch result {
            case .success:
                completion(result)
            case .failure:
                if retryCount > 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + pauseTime) {
                        self.retry(retryCount - 1, pauseTime * 2, request, completion)
                    }
                } else {
                    completion(result)
                }
            }
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - result: the parsed result object or error
    @discardableResult
    func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ result: Result<T, SnabbleError>) -> () ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: false) { result, json, headers in
            completion(result)
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - result: the parsed result object or error
    ///   - response: the HTTPURLResponse object
    @discardableResult
    func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ result: Result<T, SnabbleError>, _ response: HTTPURLResponse?) -> () ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: false) { result, json, response in
            completion(result, response)
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - returnRaw: indicates whether the raw JSON data should be returned along with the decoded data
    ///   - completion: called on the main thread when the request has finished.
    ///   - result: the parsed result object or error
    ///   - raw: the JSON structure returned by the server, or nil if an error occurred
    ///   - response: the HTTPURLResponse object if available
    @discardableResult
    func perform<T: Decodable>(_ request: URLRequest, returnRaw: Bool, _ completion: @escaping (_ result: Result<T, SnabbleError>, _ raw: [String: Any]?, _ response: HTTPURLResponse?) -> () ) -> URLSessionDataTask {
        let start = Date.timeIntervalSinceReferenceDate
        let session = SnabbleAPI.urlSession()
        let task = session.dataTask(with: request) { rawData, response, error in
            let elapsed = Date.timeIntervalSinceReferenceDate - start
            let url = request.url?.absoluteString ?? "n/a"
            Log.info("get \(url) took \(elapsed)s")
            guard
                let data = rawData,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 || httpResponse.statusCode == 201
            else {
                self.logError("error getting response from \(url): \(String(describing: error))")
                var apiError = SnabbleError.unknown
                if let data = rawData {
                    do {
                        let error = try JSONDecoder().decode(SnabbleError.self, from: data)
                        self.logError("error response: \(String(describing: error))")
                        apiError = error
                    }
                    catch {
                        let rawResponse = String(bytes: data, encoding: .utf8)
                        self.logError("failed parsing error response: \(String(describing: rawResponse)) -> \(error)")
                    }
                }
                DispatchQueue.main.async {
                    completion(Result.failure(apiError), nil, response as? HTTPURLResponse)
                }
                return
            }

            // handle empty response
            if data.count == 0 {
                DispatchQueue.main.async {
                    completion(Result.failure(SnabbleError.empty), nil, httpResponse)
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
                    completion(Result.success(result), json, httpResponse)
                }
            } catch {
                Log.error("error parsing response from \(url): \(error)")
                let body = String(bytes: data, encoding: .utf8) ?? ""
                Log.error("raw response body: \(body)")
                DispatchQueue.main.async {
                    completion(Result.failure(SnabbleError.invalid), nil, httpResponse)
                }
            }
        }
        task.resume()
        return task
    }

}

extension Project {

    public func logError(_ msg: String) {
        Log.error(msg)

        let event = AppEvent(error: msg, project: self)
        event.post()
    }

    public func logMsg(_ msg: String) {
        let event = AppEvent(log: msg, project: self)
        event.post()
    }
}


