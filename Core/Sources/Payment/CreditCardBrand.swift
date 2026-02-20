//
//  CreditCardBrand.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

// unfortunately we have to maintain a bunch of different mappings to strings and other types
public enum CreditCardBrand: String, Codable, CaseIterable, Sendable {
    // 1st mapping: from the reponse of the IPG card entry form; also used for datatrans
    case visa
    case mastercard
    case amex

    // 2nd mapping: to the `cardType` property of the encrypted payment data
    var cardType: String {
        switch self {
        case .visa: return "creditCardVisa"
        case .mastercard: return "creditCardMastercard"
        case .amex: return "creditCardAmericanExpress"
        }
    }

    // 3rd mapping: to the `paymentMethod` form field of the IPG card entry form
    // also used for mapping from/to Payone "cardtype"
    public  var paymentMethod: String {
        switch self {
        case .visa: return "V"
        case .mastercard: return "M"
        case .amex: return "A"
        }
    }

    // 4th mapping: to a user-facing string
    public var displayName: String {
        switch self {
        case .visa: return "VISA"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        }
    }

    // 5th mapping: from brand to RawPaymentMethod
    public var method: RawPaymentMethod {
        switch self {
        case .visa: return .creditCardVisa
        case .mastercard: return .creditCardMastercard
        case .amex: return .creditCardAmericanExpress
        }
    }

    public static func forMethod(_ method: RawPaymentMethod) -> CreditCardBrand? {
        switch method {
        case .creditCardVisa: return .visa
        case .creditCardMastercard: return .mastercard
        case .creditCardAmericanExpress: return .amex
        default: return nil
        }
    }

    static func forType(_ type: String) -> CreditCardBrand? {
        allCases.first { $0.paymentMethod == type }
    }
}

// so that we can access cc brands regardless of payment gateway
public protocol BrandedCreditCard {
    var brand: CreditCardBrand { get }
}
