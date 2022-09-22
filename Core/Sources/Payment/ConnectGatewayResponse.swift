//
//  ConnectGatewayResponse.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

// response data from the telecash IPG Connect API
public struct ConnectGatewayResponse: Decodable {
    public enum Error: Swift.Error {
        case gateway(reason: String, code: String)
        case responseCode(String)
        case empty(variableLabel: String?)
    }

    enum CodingKeys: String, CodingKey {
        case responseCode = "processor_response_code"

        case hostedDataId = "hosteddataid"
        case schemeTransactionId = "schemeTransactionId"

        case cardNumber = "cardnumber"
        case cardHolder = "bname"
        case brand = "ccbrand"
        case expMonth = "expmonth"
        case expYear = "expyear"

        case orderId = "oid"

        case failReason = "fail_reason"
        case failCode = "fail_rc"
    }

    let hostedDataId: String
    let schemeTransactionId: String
    let cardNumber: String
    let cardHolder: String
    let brand: String
    let expMonth: String
    let expYear: String
    let responseCode: String
    let orderId: String

    public init(response: [[String: String]]) throws {
        let reducedResponse = response.reduce([:], { (result: [String: String], element: [String: String]) in
            guard let name = element["name"], let value = element["value"], !value.isEmpty else {
                return result
            }
            var result = result
            result[name] = value
            return result
        })
        let jsonDecoder = JSONDecoder()
        let jsonData = try JSONSerialization.data(withJSONObject: reducedResponse, options: .fragmentsAllowed)
        let instance = try jsonDecoder.decode(Self.self, from: jsonData)

        hostedDataId = instance.hostedDataId
        schemeTransactionId = instance.schemeTransactionId
        cardNumber = instance.cardNumber
        cardHolder = instance.cardHolder
        brand = instance.brand
        expMonth = instance.expMonth
        expYear = instance.expYear
        responseCode = instance.responseCode
        orderId = instance.orderId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let failReason = try container.decodeIfPresent(String.self, forKey: .failReason)
        let failCode = try container.decodeIfPresent(String.self, forKey: .failCode)

        if let failReason = failReason, let failCode = failCode, !failCode.isEmpty {
            throw Error.gateway(reason: failReason, code: failCode)
        }

        hostedDataId = try container.decode(String.self, forKey: .hostedDataId)
        schemeTransactionId = try container.decode(String.self, forKey: .schemeTransactionId)
        cardNumber = try container.decode(String.self, forKey: .cardNumber)
        cardHolder = try container.decode(String.self, forKey: .cardHolder)
        brand = try container.decode(String.self, forKey: .brand)
        expMonth = try container.decode(String.self, forKey: .expMonth)
        expYear = try container.decode(String.self, forKey: .expYear)
        responseCode = try container.decode(String.self, forKey: .responseCode)
        orderId = try container.decode(String.self, forKey: .orderId)

        // Validation

        guard responseCode == "00" else {
            throw Error.responseCode(responseCode)
        }

        try Mirror(reflecting: self)
            .children
            .filter { $0.value is String }
            .forEach {
                if let value = $0.value as? String {
                    guard !value.isEmpty else {
                        throw Error.empty(variableLabel: $0.label)
                    }
                }
            }
    }
}
