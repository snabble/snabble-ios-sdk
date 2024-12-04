//
//  Snabble+URLSession.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-12-03.
//

import Foundation

extension Snabble {
    ///
    /// get a URLSession that is suitable for making requests to the snabble servers
    /// and verifies the CAs
    ///
    /// - Returns: a URLSession object
    public static var urlSession: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpCookieStorage = nil
        return URLSession(configuration: sessionConfiguration)
    }()
}
