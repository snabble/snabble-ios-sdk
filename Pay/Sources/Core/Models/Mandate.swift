//
//  Mandate.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-31.
//

import Foundation
import Tagged
import SnabblePayNetwork

extension Account {
    /// The SEPA-Mandate information
    public struct Mandate {
        /// Unique identifier of the mandate
        public let id: ID

        /// Current State of the mandate see `Account.Mandate.State`
        public let state: State

        /// Description of the mandate
        public let htmlText: String?

        /// Constants indicating the mandate's state to use snabble pay
        public enum State: String, Decodable {
            /// Mandate has to be created
            case missing = "MISSING"
            /// The user has not chosen whether the linked bank account can be used for a session
            case pending = "PENDING"
            /// The user authorized the mandate to be able to use the linked bank account for a session
            case accepted = "ACCEPTED"
            /// The user declined the mandate
            case declined = "DECLINED"
        }

        /// Type Safe Identifier
        public typealias ID = Tagged<Account, String>
    }
}

extension Account.Mandate: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Account.Mandate: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Account.Mandate) {
        self.id = ID(dto.id)
        self.state = .init(fromDTO: dto.state)
        self.htmlText = dto.htmlText
    }
}

extension Account.Mandate.State: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Account.Mandate.State) {
        switch dto {
        case .missing:
            self = .missing
        case .declined:
            self = .declined
        case .pending:
            self = .pending
        case .accepted:
            self = .accepted
        }
    }
}

extension SnabblePayNetwork.Account.Mandate: ToModel {
    func toModel() -> Account.Mandate {
        .init(fromDTO: self)
    }
}
