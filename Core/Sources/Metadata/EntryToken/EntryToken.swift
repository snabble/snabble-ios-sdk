//
//  EntryToken.swift
//
//
//  Created by Andreas Osberghaus on 2023-09-05.
//

import Foundation

public protocol EntryToken: Codable {
    var value: String { get }
    var validUntil: Date { get }
    var refreshAfter: Date { get }
}
