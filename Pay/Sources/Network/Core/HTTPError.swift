//
//  HTTPError.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-24.
//

import Foundation

enum HTTPError {
    case invalidResponse(HTTPStatusCode, Endpoints.Error)
    case unknownResponse(URLResponse)
    case unexpected(Error)
}

extension HTTPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidResponse(httpStatusCode, error):
            return "Error: statusCode: \(httpStatusCode.rawValue) with error: \(error))"
        case let .unknownResponse(response):
            return "Error: unknown \(response)"
        case .unexpected:
            return "Error: unexpected should not happen"
        }
    }
}
