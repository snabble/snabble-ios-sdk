//
//  Endpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation

/// A namespace for types that serve as `Endpoint`.
///
/// The various endpoints defined as extensions on ``Endpoint``.
public enum Endpoints {
    public static var jsonDecoder: JSONDecoder {
        let decoder: JSONDecoder = .init()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
    
    public static var jsonEncoder: JSONEncoder {
        let encoder: JSONEncoder = .init()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }
}

public struct Endpoint<Response>: @unchecked Sendable {
    public let method: HTTPMethod
    public let path: String

    public let parse: (Data) throws -> Response

    var token: Token?
    var headerFields: [String: String] = [:]
    var domain: Domain = .production

    /// Overrides `domain.baseURL` when set. Used by consumers (e.g. SnabblePay) whose API host
    /// isn't one of the `Domain` cases but who still want to reuse `Endpoint`'s request building.
    public var baseURLOverride: URL?

    public init(path: String, method: HTTPMethod, parse: @escaping (Data) throws -> Response) {
        self.path = path
        self.method = method
        self.parse = parse
    }

    enum Error: Swift.Error {
        case invalidRequestError(String)
    }
}

extension Endpoint {
    /// Returns a copy of this endpoint with the given base URL and/or additional header fields applied.
    public func with(baseURLOverride: URL? = nil, additionalHeaderFields: [String: String] = [:]) -> Endpoint<Response> {
        var copy = self
        if let baseURLOverride {
            copy.baseURLOverride = baseURLOverride
        }
        if !additionalHeaderFields.isEmpty {
            copy.headerFields.merge(additionalHeaderFields, uniquingKeysWith: { _, new in new })
        }
        return copy
    }
}

extension Endpoint {
    public func urlRequest() throws -> URLRequest {
        var components = URLComponents(
            url: baseURLOverride ?? domain.baseURL,
            resolvingAgainstBaseURL: false
        )
        components?.path = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path

        switch method {
        case .get(let queryItems):
            components?.queryItems = queryItems?.sorted(by: \.name)
        default:
            break
        }

        guard let url = components?.url else {
            throw Error.invalidRequestError("baseURL: \(domain.baseURL), path: \(path)")
        }

        var request = URLRequest(url: url)

        switch method {
        case .post(let data), .put(let data), .patch(let data):
            request.httpBody = data
        default:
            request.httpBody = nil
        }

        let headerFields = domain.headerFields.merging(headerFields, uniquingKeysWith: { _, new in new })
        request.allHTTPHeaderFields = headerFields

        if let token = token {
            request.setValue("Bearer \(token.value)", forHTTPHeaderField: "Authorization")
        }

        request.httpMethod = method.value
        request.cachePolicy = .useProtocolCachePolicy

        return request
    }
}
