//
//  CheckoutData.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

/// Signed Checkout Info
public struct SignedCheckoutInfo: Decodable {
    public let checkoutInfo: CheckoutInfo
    public let signature: String
    public let links: CheckoutLinks

    enum CodingKeys: String, CodingKey {
        case checkoutInfo
        case signature
        case links
    }

    public struct CheckoutLinks: Decodable {
        public let checkoutProcess: Link
    }

    // not part of the Snabble API, only used internally
    var rawJson: [String: Any]? = nil
}

// known payment methods
public enum PaymentMethod: String {
    case cash
//    case girocard
//    case sepa
//    case visa
//    case mastercard
    case qrCode = "qrCodePOS"
    case encodedCodes
}

public enum PaymentState: String, Decodable {
    case pending
    case successful
    case failed
}

// CheckoutInfo
public struct CheckoutInfo: Decodable {
    public let price: Price
    public let availableMethods: [String]
    public let shopID: String
    public let project: String
    public let session: String

// we dont need line items right now, so we just ignore them
//    public let lineItems: [LineItem]
//    public struct LineItem: Decodable {
//        public let totalPrice: Int
//        public let amount: Int
//        public let name: String
//        public let price: Int
//        public let taxRate: Int
//        public let sku: String
//    }

    public struct Price: Decodable {
        public let tax: Tax
        public let netPrice: Int
        public let price: Int

        public struct Tax: Decodable {
            public let tax0, tax7, tax19: Int?

            public enum CodingKeys: String, CodingKey {
                case tax0 = "0"
                case tax7 = "7"
                case tax19 = "19"
            }
        }
    }

    public var paymentMethods: [PaymentMethod] {
        return availableMethods.compactMap { PaymentMethod(rawValue: $0) }
    }
}

/// Checkout Process
public struct CheckoutProcess: Decodable {
    public let links: ProcessLinks
    public let supervisorApproval: Bool?
    public let paymentApproval: Bool?
    public let aborted: Bool
    public let checkoutInfo: CheckoutInfo
    public let paymentMethod: String
    public let modified: Bool
    public let paymentInformation: PaymentInformation?
    public let paymentState: PaymentState

    public struct ProcessLinks: Decodable {
        public let `self`: Link
        public let approval: Link
    }

    public struct PaymentInformation: Decodable {
        // for method == .qrCode
        public let qrCodeContent: String?
    }
}

// MARK: - data we send to the server

/// Cart
struct Cart: Encodable {
    let session: String
    let shopID: String
    let customer: CustomerInfo?
    let items: [Item]

    struct Item: Encodable {
        let sku: String
        let amount: Int
        let scannedCode: String

        let price: Int?
        let weight: Int?
        let units: Int?
    }

    struct CustomerInfo: Encodable {
        let loyaltyCard: String

        init?(loyaltyCard: String?) {
            guard let c = loyaltyCard else {
                return nil
            }
            self.loyaltyCard = c
        }
    }
}

/// AbortRequest
struct AbortRequest: Encodable {
    let aborted: Bool
}
