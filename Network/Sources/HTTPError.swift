//
//  HTTPError.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-24.
//

import Foundation

public enum HTTPError: Error {
    case invalid(HTTPURLResponse, ClientError?)
    case unknown(URLResponse)
    case unexpected(Error)
}
