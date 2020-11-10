//
//  Project+Network.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

public struct SnabbleError: Decodable, Error, Equatable {
    public let error: ErrorResponse

    static let unknown = SnabbleError(error: ErrorResponse("unknown"))
    static let empty = SnabbleError(error: ErrorResponse("empty"))
    static let invalid = SnabbleError(error: ErrorResponse("invalid"))
    static let noRequest = SnabbleError(error: ErrorResponse("no request"))
    static let notFound = SnabbleError(error: ErrorResponse("not found"))
    static let cancelled = SnabbleError(error: ErrorResponse("cancelled"))

    static let noPaymentAvailable = SnabbleError(error: ErrorResponse("no payment method available"))
}

public enum ProductLookupError: Error, Equatable {
    case notFound
    case networkError(URLError.Code)
    case serverError(Int)

    var statusCode: Int? {
        switch self {
        case .serverError(let statusCode): return statusCode
        default: return nil
        }
    }

    static func from(_ response: URLResponse?) -> ProductLookupError? {
        guard let response = response as? HTTPURLResponse else {
            return nil
        }

        switch response.statusCode {
        case 200: return nil
        case 404: return .notFound
        default: return .serverError(response.statusCode)
        }
    }

    static func from(_ error: Error?) -> ProductLookupError? {
        guard let error = error as? URLError else {
            return nil
        }
        return .networkError(error.code)
    }
}

public enum ErrorResponseType: String, UnknownCaseRepresentable {
    case unknown

    // checkout errors
    case invalidCartItem = "invalid_cart_item"
    case shopNotFound = "shop_not_found"
    case badShopId = "bad_shop_id"
    case noAvailableMethod = "no_available_method"

    case checkoutUnavailable = "checkout_unavailable"

    // invalidCartItem detail types
    case saleStop = "sale_stop"
    case productNotFound = "product_not_found"

    public static let unknownCase = ErrorResponseType.unknown
}

public struct ErrorResponse: Decodable, Equatable {
    public let rawType: String
    public let message: String?
    public let sku: String?
    public let details: [ErrorResponse]?

    enum CodingKeys: String, CodingKey {
        case rawType = "type"
        case details, sku, message
    }

    init(_ type: String) {
        self.rawType = type
        self.details = nil
        self.message = nil
        self.sku = nil
    }

    var type: ErrorResponseType {
        return ErrorResponseType(rawValue: self.rawType)
    }
}

enum HTTPRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// for those API calls where we need both the decoded result as well as the raw json data as a dictionary
public struct RawResult<T, E: Swift.Error> {
    public let result: Result<T, E>
    public let rawJson: [String: Any]?
    public let statusCode: Int

    public init(_ value: T, statusCode: Int, rawJson: [String: Any]? = nil) {
        self.result = Result.success(value)
        self.rawJson = rawJson
        self.statusCode = statusCode
    }

    public init(_ result: Result<T, E>, statusCode: Int, rawJson: [String: Any]? = nil) {
        self.result = result
        self.rawJson = rawJson
        self.statusCode = statusCode
    }

    public static func failure(_ error: E) -> RawResult {
        return RawResult(Result.failure(error), statusCode: 0, rawJson: nil)
    }
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
    func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, jwtRequired: Bool = true, parameters: [String: String]? = nil,
                 timeout: TimeInterval, completion: @escaping (URLRequest?) -> Void) {
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
    func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, jwtRequired: Bool = true, queryItems: [URLQueryItem],
                 timeout: TimeInterval, completion: @escaping (URLRequest?) -> Void) {
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
    func request(_ method: HTTPRequestMethod, _ url: String, body: Data, timeout: TimeInterval, completion: @escaping (URLRequest?) -> Void) {
        guard let url = SnabbleAPI.urlFor(url) else {
            return completion(nil)
        }

        self.request(method, url, true, true, timeout) { request in
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
    func request<T: Encodable>(_ method: HTTPRequestMethod, _ url: String, body: T, timeout: TimeInterval = 0, _ completion: @escaping (URLRequest?) -> Void ) {
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
    // swiftlint:disable:next function_parameter_count
    func request(_ method: HTTPRequestMethod, _ url: URL, _ json: Bool, _ jwtRequired: Bool, _ timeout: TimeInterval, _ completion: @escaping (URLRequest) -> Void) {
        var urlRequest = SnabbleAPI.request(url: url, timeout: timeout, json: json)
        urlRequest.httpMethod = method.rawValue

        if jwtRequired {
            SnabbleAPI.tokenRegistry.getToken(for: self) { token in
                if let token = token {
                    urlRequest.addValue(token, forHTTPHeaderField: "Client-Token")
                }
                completion(urlRequest)
            }
        } else {
            completion(urlRequest)
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - retryCount: how often the request should be retried on failure
    ///   - pauseTime: how long (in seconds) to wait after a failed request. This value is doubled for each retry after the first.
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - result: the parsed result object or error
    func retry<T: Decodable>(_ retryCount: Int, _ pauseTime: TimeInterval, _ request: URLRequest, _ completion: @escaping (_ result: Result<T, SnabbleError>) -> Void ) {
        self.perform(request) { (result: Result<T, SnabbleError>) in
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
    func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ result: Result<T, SnabbleError>) -> Void ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: false) { result, _, _ in
            completion(result)
        }
    }

    /// perfom an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - result: the parsed result object plus its raw JSON data, or error
    @discardableResult
    func performRaw<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ result: RawResult<T, SnabbleError>) -> Void ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: true) { (_ result: Result<T, SnabbleError>, _ raw: [String: Any]?, response: HTTPURLResponse?) in
            let statusCode = response?.statusCode ?? 0
            let rawResult = RawResult(result, statusCode: statusCode, rawJson: raw)
            completion(rawResult)
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
    func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ result: Result<T, SnabbleError>, _ response: HTTPURLResponse?) -> Void ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: false) { result, _, response in
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
    private func perform<T: Decodable>(_ request: URLRequest, returnRaw: Bool, _ completion: @escaping (_ result: Result<T, SnabbleError>, _ raw: [String: Any]?,
                               _ response: HTTPURLResponse?) -> Void ) -> URLSessionDataTask {
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
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

                let cancelled: Bool = {
                    if let urlError = error as? URLError, urlError.code == .cancelled {
                        return true
                    }
                    return false
                }()

                if !cancelled {
                    self.logError("error getting response from \(url): \(String(describing: error)) statusCode \(statusCode)")
                } else {
                    Log.error("request was cancelled: \(url)")
                }

                var apiError = SnabbleError.unknown
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    apiError = SnabbleError.cancelled
                }
                if let data = rawData {
                    do {
                        let error = try JSONDecoder().decode(SnabbleError.self, from: data)
                        self.logError("error response: \(String(describing: error))")
                        apiError = error
                    } catch {
                        let rawResponse = String(bytes: data, encoding: .utf8)
                        self.logError("failed parsing error response: \(String(describing: rawResponse)) -> \(error)")
                    }
                }
                DispatchQueue.main.async {
                    completion(.failure(apiError), nil, response as? HTTPURLResponse)
                }
                return
            }

            // handle empty response
            if data.isEmpty {
                DispatchQueue.main.async {
                    completion(.failure(SnabbleError.empty), nil, httpResponse)
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
                    completion(.success(result), json, httpResponse)
                }
            } catch {
                Log.error("error parsing response from \(url): \(error)")
                let body = String(bytes: data, encoding: .utf8) ?? ""
                Log.error("raw response body: \(body)")
                DispatchQueue.main.async {
                    completion(.failure(SnabbleError.invalid), nil, httpResponse)
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
