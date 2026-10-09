//
//  Transaction.swift
//  
//
//  Created by Andreas Osberghaus on 2023-04-06.
//

import Foundation
import Tagged
import SnabblePayNetwork

/// The transaction object of a `Session`
public struct Transaction {
    /// Unique identifier of a transaction
    public let id: ID
    /// Current State of the transaction see `Session.Transaction.State`
    public let state: State
    /// A Integer that represents an amount of money in the minor unit of the `currencyCode`
    public let amount: Int
    /// A string that represents the used currency
    public let currencyCode: String

    /// Type Safe Identifier
    public typealias ID = Tagged<Transaction, String>

    /// Constants indicating the transaction's state
    public enum State: String, Decodable {
        /// Amount was sucessfully preauthorized
        case preauthorizationSuccessful = "PREAUTHORIZATION_SUCCESSFUL"
        /// Preauthorization failed
        case preauthorizationFailed = "PREAUTHORIZATION_FAILED"
        /// Transaction was successfuly captured
        case successful = "SUCCESSFUL"
        /// Capture failed
        case failed = "FAILED"
        /// Error while processing the transaction
        case errored = "ERRORED"
        /// Transaction aborted
        case aborted = "ABORTED"
    }
}

extension Transaction.State: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Transaction.State) {
        switch dto {
        case .preauthorizationSuccessful:
            self = .preauthorizationSuccessful
        case .preauthorizationFailed:
            self = .preauthorizationFailed
        case .successful:
            self = .successful
        case .failed:
            self = .failed
        case .errored:
            self = .errored
        case .aborted:
            self = .aborted
        }
    }
}

extension Transaction: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Transaction) {
        self.id = ID(dto.id)
        self.state = .init(fromDTO: dto.state)
        self.amount = dto.amount
        self.currencyCode = dto.currencyCode
    }
}
