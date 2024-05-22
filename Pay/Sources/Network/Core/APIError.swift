//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-28.
//

import Foundation

public enum APIError: LocalizedError {
    /// Invalid request, e.g. invalid URL
    case invalidRequestError(String)

    /// Indicates an error on the transport layer, e.g. not being able to connect to the server
    case transportError(URLError)

    /// Received an invalid response, e.g. non-HTTP result
    case invalidResponse(URLResponse)

    /// Server-side validation error
    case validationError(HTTPStatusCode, Endpoints.Error)

    /// The server sent data in an unexpected format
    case decodingError(DecodingError)

    /// Unexpected error within the flow
    case unexpected(Error)
}
