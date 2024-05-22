//
//  AccountCheck.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-31.
//

import Foundation
import SnabblePayNetwork

extension Account {
    /// Tink Account Check Object
    public struct Check {
        /// Link to start account check verification process
        public let validationURL: URL
        /// Your custom url-scheme of the hosted app
        public let appUri: URL
    }
}

extension Account.Check: Identifiable {
    /// id is the `validationURL`. It's added to support `Identifiable` protocol
    public var id: URL {
        validationURL
    }
}

extension Account.Check: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Account.Check) {
        self.validationURL = dto.validationURL
        self.appUri = dto.appUri
    }
}

extension SnabblePayNetwork.Account.Check: ToModel {
    func toModel() -> Account.Check {
        .init(fromDTO: self)
    }
}
