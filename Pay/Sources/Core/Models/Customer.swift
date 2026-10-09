//
//  Customer.swift
//  
//
//  Created by Andreas Osberghaus on 2023-03-16.
//

import Foundation
import SnabblePayNetwork

/// Customer information
public struct Customer: Decodable {
    /// id of the customer in your database
    let id: String?
    /// loyalty number or id in your database
    let loyaltyId: String?
}

extension Customer: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Customer: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Customer) {
        id = dto.id
        loyaltyId = dto.id
    }
}

extension SnabblePayNetwork.Customer: ToModel {
    func toModel() -> Customer {
        .init(fromDTO: self)
    }
}
