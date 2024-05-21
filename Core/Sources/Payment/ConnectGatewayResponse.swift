//
//  ConnectGatewayResponse.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

// response data from the telecash IPG Connect API
public struct ConnectGatewayResponse: Decodable {
    let hostedDataId: String
    let schemeTransactionId: String
    let cardNumber: String
    let cardHolder: String
    let ccBrand: String
    let expMonth: String
    let expYear: String
    let responseCode: String
    let transactionId: String
    let storeId: String
}
