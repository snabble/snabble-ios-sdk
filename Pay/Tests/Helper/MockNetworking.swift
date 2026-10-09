//
//  MockNetworking.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import Foundation

extension URLSession {
    public static var mockSession: URLSession {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
