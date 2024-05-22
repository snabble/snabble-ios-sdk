//
//  Transaction.swift
//  
//
//  Created by Andreas Osberghaus on 2023-04-06.
//

import Foundation

public struct Transaction: Decodable {
    public let id: String
    public let state: State
    public let amount: Int
    public let currencyCode: String

    public enum State: String, Decodable {
        case preauthorizationSuccessful = "PREAUTHORIZATION_SUCCESSFUL"
        case preauthorizationFailed = "PREAUTHORIZATION_FAILED"
        case successful = "SUCCESSFUL"
        case failed = "FAILED"
        case errored = "ERRORED"
        case aborted = "ABORTED"
    }
}
