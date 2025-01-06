//
//  Project+Network.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

public enum SnabbleError: Error, Equatable {
    case unknown

    // unable to even make the HTTP request (e.g. no or invalid URL)
    case noRequest

    // HTTP status was OK, but response was empty
    case empty

    // HTTP status was OK, but response parsing failed
    case invalid

    // the URL loading failed
    case urlError(URLError)

    // the HTTP request failed
    case httpError(statusCode: Int)

    // structured error from the snabble backend
    case apiError(error: SnabbleAPIError, statusCode: Int)

    public var details: [ErrorResponse]? {
        switch self {
        case .apiError(let apiError, _):
            return apiError.error.details
        default:
            return nil
        }
    }

    public var type: ErrorResponseType {
        switch self {
        case .apiError(let apiError, _):
            return apiError.error.type
        default:
            return .unknown
        }
    }

    var statusCode: Int? {
        switch self {
        case .apiError(_, let statusCode): return statusCode
        case .httpError(let statusCode): return statusCode
        default: return nil
        }
    }

    public func isUrlError(_ code: URLError.Code) -> Bool {
        switch self {
        case .urlError(let urlError):
            return urlError.code == code
        default:
            return false
        }
    }
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

    // client error, used e.g. for "conflicting version" in the terms consent
    case clientError = "client_error"

    public static let unknownCase = ErrorResponseType.unknown
}

public struct ErrorResponse: Decodable, Equatable {
    public let rawType: String
    public let message: String?
    public let sku: String?
    public let id: String?
    public let details: [ErrorResponse]?

    enum CodingKeys: String, CodingKey {
        case rawType = "type"
        case details, sku, message, id
    }

    init(_ type: String) {
        self.rawType = type
        self.details = nil
        self.message = nil
        self.sku = nil
        self.id = nil
    }

    var type: ErrorResponseType {
        return ErrorResponseType(rawValue: self.rawType)
    }
}

public struct SnabbleAPIError: Decodable, Error, Equatable {
    public let error: ErrorResponse
}

public enum HTTPRequestMethod: String {
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

    public init(_ value: T, rawJson: [String: Any]? = nil) {
        self.result = Result.success(value)
        self.rawJson = rawJson
    }

    public init(_ result: Result<T, E>, rawJson: [String: Any]? = nil) {
        self.result = result
        self.rawJson = rawJson
    }

    public static func failure(_ error: E) -> RawResult {
        return RawResult(Result.failure(error), rawJson: nil)
    }
}

private extension Dictionary where Key == String, Value == String {
    func queryItems() -> [URLQueryItem] {
        map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
    }
}

private extension String {
    func urlString(with queryItems: [URLQueryItem]?) -> String? {
        guard var urlComponents = URLComponents(string: self) else {
            return nil
        }
        if let queryItems = queryItems, !queryItems.isEmpty {
            if urlComponents.queryItems == nil {
                urlComponents.queryItems = queryItems
            } else {
                urlComponents.queryItems?.append(contentsOf: queryItems)
            }
        }

        return urlComponents.url?.absoluteString
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
    public func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, jwtRequired: Bool = true, parameters: [String: String]? = nil, timeout: TimeInterval, completion: @escaping (URLRequest?) -> Void) {
        request(method, url, json: json, jwtRequired: jwtRequired, queryItems: parameters?.queryItems(), timeout: timeout, completion: completion)
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
    public func request(_ method: HTTPRequestMethod, _ url: String, json: Bool = true, jwtRequired: Bool = true, queryItems: [URLQueryItem]?, timeout: TimeInterval, completion: @escaping (URLRequest?) -> Void) {
        guard
            let url = url.urlString(with: queryItems),
            let fullUrl = Snabble.shared.urlFor(url)
        else {
            return completion(nil)
        }

        request(method, fullUrl, json, jwtRequired, timeout, completion)
    }

    /// create an URLRequest
    ///
    /// - Parameters:
    ///   - method: the HTTP method to use
    ///   - url: the URL to use
    ///   - body: the JSON data to send as the HTTP body
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    /// - Returns: the URLRequest
    public func request(_ method: HTTPRequestMethod, _ url: String, body: Data, timeout: TimeInterval, completion: @escaping (URLRequest?) -> Void) {
        guard let url = Snabble.shared.urlFor(url) else {
            return completion(nil)
        }

        request(method, url, true, true, timeout) { request in
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
    public func request<T: Encodable>(_ method: HTTPRequestMethod, _ url: String, body: T, timeout: TimeInterval = 0, _ completion: @escaping (URLRequest?) -> Void ) {
        guard let url = Snabble.shared.urlFor(url) else {
            return completion(nil)
        }

        request(method, url, true, true, timeout) { request in
            do {
                var urlRequest = request
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                urlRequest.httpBody = try encoder.encode(body)
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
    ///   - completion: the URLRequest
    public func request(_ method: HTTPRequestMethod, _ url: URL, _ json: Bool, _ jwtRequired: Bool, _ timeout: TimeInterval, _ completion: @escaping (URLRequest) -> Void) {
        var urlRequest = Snabble.request(url: url, timeout: timeout, json: json)
        urlRequest.httpMethod = method.rawValue

        if jwtRequired {
            Snabble.shared.tokenRegistry.getToken(for: self) { token in
                if let token = token {
                    urlRequest.addValue(token, forHTTPHeaderField: "Client-Token")
                }
                completion(urlRequest)
            }
        } else {
            completion(urlRequest)
        }
    }

    /// perform an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - result: the parsed result object or error
    @discardableResult
    public func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ result: Result<T, SnabbleError>) -> Void ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: false) { result, _, _ in
            completion(result)
        }
    }

    /// perform an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - result: the parsed result object plus its raw JSON data, or error
    @discardableResult
    func performRaw<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ result: RawResult<T, SnabbleError>) -> Void ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: true) { (_ result: Result<T, SnabbleError>, _ raw: [String: Any]?, _) in
            let rawResult = RawResult(result, rawJson: raw)
            completion(rawResult)
        }
    }

    /// perform an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - completion: called on the main thread when the result is available.
    ///   - result: the parsed result object or error
    ///   - response: the HTTPURLResponse object
    @discardableResult
    public func perform<T: Decodable>(_ request: URLRequest, _ completion: @escaping (_ result: Result<T, SnabbleError>, _ response: HTTPURLResponse?) -> Void ) -> URLSessionDataTask {
        return self.perform(request, returnRaw: false) { result, _, response in
            completion(result, response)
        }
    }

    /// perform an API Request
    ///
    /// - Parameters:
    ///   - request: the `URLRequest` to perform
    ///   - returnRaw: indicates whether the raw JSON data should be returned along with the decoded data
    ///   - completion: called on the main thread when the request has finished.
    ///   - result: the parsed result object or error
    ///   - raw: the JSON structure returned by the server, or nil if an error occurred
    ///   - response: the HTTPURLResponse object if available
    @discardableResult
    private func perform<T: Decodable>(_ request: URLRequest, returnRaw: Bool, _ completion: @escaping (_ result: Result<T, SnabbleError>, _ raw: [String: Any]?, _ response: HTTPURLResponse?) -> Void ) -> URLSessionDataTask {
        let start = Date.timeIntervalSinceReferenceDate
        let session = Snabble.urlSession
        let task = session.dataTask(with: request) { data, response, error in
            let elapsed = Date.timeIntervalSinceReferenceDate - start
            let url = request.url?.absoluteString ?? "n/a"
            let method = request.httpMethod ?? ""
            Log.info("\(method) \(url) took \(elapsed)s")

            // handle URL errors
            if let error = error {
                let urlError = self.snabbleError(for: error, method, url)
                DispatchQueue.main.async {
                    completion(.failure(urlError), nil, nil)
                }
                return
            }

            // check presence of data AND an "OK" HTTP response
            guard
                let data = data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 || httpResponse.statusCode == 201
            else {
                // handle HTTP error responses
                let httpError = self.snabbleError(for: response, method, url, data)
                DispatchQueue.main.async {
                    completion(.failure(httpError), nil, response as? HTTPURLResponse)
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

            // finally, decode the response object
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .customISO8601
                let result = try decoder.decode(T.self, from: data)
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

    private func snabbleError(for error: Error, _ method: String, _ url: String) -> SnabbleError {
        guard let urlError = error as? URLError else {
            return SnabbleError.unknown
        }

        let cancelled = urlError.code == .cancelled
        if !cancelled {
            self.logError("error getting response from \(method) \(url): \(String(describing: error))")
        } else {
            Log.error("request was cancelled: \(url)")
        }

        return SnabbleError.urlError(urlError)
    }

    private func snabbleError(for response: URLResponse?, _ method: String, _ url: String, _ data: Data?) -> SnabbleError {
        guard let response = response as? HTTPURLResponse else {
            return SnabbleError.unknown
        }

        if let data = data {
            let contentType = response.allHeaderFields["Content-Type"] as? String ?? ""
            let isJsonResponse = contentType.lowercased().starts(with: "application/json")
            if isJsonResponse {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .customISO8601
                    let error = try decoder.decode(SnabbleAPIError.self, from: data)
                    Log.error("error response: \(String(describing: error)) - statuscode \(response.statusCode)")
                    return SnabbleError.apiError(error: error, statusCode: response.statusCode)
                } catch {
                    let rawResponse = String(bytes: data, encoding: .utf8) ?? ""
                    self.logError("failed parsing error response: \(rawResponse) -> \(error)")
                }
            } else {
                let rawResponse = String(bytes: data, encoding: .utf8) ?? ""
                Log.error("got error response: \(rawResponse), statusCode: \(response.statusCode)")
            }
        }
        return SnabbleError.httpError(statusCode: response.statusCode)
    }
}

extension Project {
    public func logError(_ msg: String) {
        Log.error(msg)

        let event = AppEvent(error: msg, project: self)
        event.post()
    }
}
