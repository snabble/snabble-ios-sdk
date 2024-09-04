//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2024-09-04.
//

import Foundation

public protocol Configurable {
    /// the appID assigned by snabble
    var appId: String { get }
    /// the snabble domain
    var domainName: String { get }
}
