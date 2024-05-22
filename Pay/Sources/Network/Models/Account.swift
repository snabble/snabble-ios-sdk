//
//  Account.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-31.
//

import Foundation

public struct Account: Decodable {
    public let id: String
    public let name: String
    public let holderName: String
    public let currencyCode: String
    public let bank: String
    public let createdAt: Date
    public let iban: String
    public let mandateState: Mandate.State
}
