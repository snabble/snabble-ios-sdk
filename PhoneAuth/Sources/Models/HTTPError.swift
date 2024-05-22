//
//  HTTPError.swift
//  
//
//  Created by Andreas Osberghaus on 2024-02-06.
//

import Foundation
import SnabbleNetwork

public enum HTTPError: LocalizedError {
    case invalid(HTTPURLResponse, ClientError?)
    case unknown(URLResponse)
    case unexpected(Error)

    public var errorDescription: String? {
        switch self {
        case let .invalid(response, clientError):
            if let clientError {
                return clientError.message
            } else {
                return "Error: statusCode: \(response.httpStatusCode.rawValue)"
            }
        case let .unknown(response):
            return "Error: unknown \(response)"
        case .unexpected:
            return "Error: unexpected should not happen"
        }
    }
}

extension SnabbleNetwork.HTTPError {
    func fromDTO() -> HTTPError {
        switch self {
        case .invalid(let response, let clientError):
            return .invalid(response, clientError)
        case .unknown(let reponse):
            return .unknown(reponse)
        case .unexpected(let error):
            return .unexpected(error)
        }
    }
}
