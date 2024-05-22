//
//  Account.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-31.
//

import Foundation
import Tagged
import SnabblePayNetwork

/// The bank account information
public struct Account: Identifiable {
    /// Unique identifier 
    public let id: ID

    /// Name of the bank account
    public let name: String

    /// Holder name of the bank account
    public let holderName: String

    /// The currencyCode which is used by the bank account
    public let currencyCode: CurrencyCode

    /// Name of the bank
    public let bank: String

    /// Masked IBAN of the bank account
    public let iban: IBAN

    /// State of the mandate linked to the account
    public let mandateState: Mandate.State

    // Creation date of the bank account in our database
    public let createdAt: Date

    // Type Safe ID
    public typealias ID = Tagged<Account, String>

    // Type Safe IBAN
    public typealias IBAN = Tagged<(Account, iban: ()), String>

    // Type Safe CurrencyCode
    public typealias CurrencyCode = Tagged<(Account, currencyCode: ()), String>
}

extension Account: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Account: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Account: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Account) {
        self.id = ID(dto.id)
        self.name = dto.name
        self.holderName = dto.holderName
        self.currencyCode = CurrencyCode(dto.currencyCode)
        self.bank = dto.bank
        self.createdAt = dto.createdAt
        self.iban = IBAN(dto.iban)
        self.mandateState = .init(fromDTO: dto.mandateState)
    }
}

extension SnabblePayNetwork.Account: ToModel {
    func toModel() -> Account {
        .init(fromDTO: self)
    }
}
