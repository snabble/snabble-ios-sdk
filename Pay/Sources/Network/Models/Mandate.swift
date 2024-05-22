//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-31.
//

import Foundation

extension Account {
    public struct Mandate: Decodable {
        public let id: String
        public let state: State
        public let htmlText: String?

        public enum State: String, Decodable {
            case missing = "MISSING"
            case pending = "PENDING"
            case accepted = "ACCEPTED"
            case declined = "DECLINED"
        }
    }
}
