//
//  Customer.swift
//  
//
//  Created by Andreas Osberghaus on 2023-03-16.
//

import Foundation

public struct Customer: Decodable, Sendable {
    public let id: String?
    public let loyaltyId: String?
}
