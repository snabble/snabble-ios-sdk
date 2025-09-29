//
//  Order.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-11-04.
//

import Foundation

struct Orders: Decodable {
    let orders: [Order]
}

public struct Order: Decodable, Sendable {    
    public let id: String
    public let date: Date
    
    public let projectId: String
    
    public let shopId: String
    public let shopName: String
    
    public let price: Int
    public let isSuccessful: Bool
    
    let links: Links
    
    struct Links: Codable {
        let receipt: Link?
        
        struct Link: Codable {
            let href: String
        }
    }
    
    public var href: String? {
        links.receipt?.href
    }
    
    enum CodingKeys: String, CodingKey {
        case projectId = "project"
        case id, date, shopName, price
        case shopId = "shopID"
        case links
        case isSuccessful
    }
    
    public var hasReceipt: Bool {
        guard let href, !href.isEmpty else {
            return false
        }
        return true
    }
}

extension Order: Swift.Identifiable, Hashable {
    public static func == (lhs: SnabbleNetwork.Order, rhs: SnabbleNetwork.Order) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
