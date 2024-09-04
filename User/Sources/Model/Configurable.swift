//
//  Configurable.swift
//
//
//  Created by Uwe Tilemann on 15.05.24.
//

import Foundation

public protocol Configurable {
    /// the appID assigned by snabble
    var appId: String { get }
    /// the snabble domain
    var domainName: String { get }
}
