//
//  CreditCardInfo.swift
//
//
//  Created by Uwe Tilemann on 22.01.24.
//

import Foundation

public struct CreditCardInfo: Codable {
    let pseudoCardPAN: String
    let lastname: String
    let email: String
    let address: Address
    
    struct Address: Codable {
        let street: String
        let zip: String
        let city: String
        let country: String
    }
    public init(withPAN pan: String, body: [String: Any]) {
        self.pseudoCardPAN = pan
        
        self.lastname = body["lastname"] as? String ?? ""
        self.email = body["email"] as? String ?? ""
        
        self.address = Address(street: body["street"] as? String ?? "",
                               zip: body["zip"] as? String ?? "",
                               city: body["city"] as? String ?? "",
                               country: body["country"] as? String ?? "")
    }
}
