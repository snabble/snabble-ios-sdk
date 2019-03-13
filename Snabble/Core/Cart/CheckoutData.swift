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

        fileprivate init() {
            self.checkoutProcess = Link.empty
        }
    }

    // not part of the Snabble API, only used internally
    var rawJson: [String: Any]? = nil

    // only used for the embedded codes offline payment
    init() {
        self.checkoutInfo = CheckoutInfo()
        self.signature = ""
        self.links = CheckoutLinks()
    }
}

// known payment methods
public enum RawPaymentMethod: String {
    case qrCode = "qrCodePOS"
    case encodedCodes           // QR Code with EANs and separators
    case teleCashDeDirectDebit  // SEPA via Telecash
    case encodedCodesCSV        // QR Code with CSV
}

// associated data for a payment method
public struct PaymentMethodData {
    public let displayName: String
    public let encryptedData: String

    public init(_ displayName: String, _ encryptedData: String) {
        self.displayName = displayName
        self.encryptedData = encryptedData
    }
}

// payment method with associated data
public enum PaymentMethod {
    case qrCode
    case encodedCodes
    case teleCashDeDirectDebit(PaymentMethodData)
    case encodedCodesCSV

    public var rawMethod: RawPaymentMethod {
        switch self {
        case .qrCode: return .qrCode
        case .encodedCodes: return .encodedCodes
        case .teleCashDeDirectDebit: return .teleCashDeDirectDebit
        case .encodedCodesCSV: return .encodedCodesCSV
        }
    }

    public var displayName: String? {
        return self.data?.displayName
    }

    public var data: PaymentMethodData? {
        switch self {
        case .teleCashDeDirectDebit(let data): return data
        default: return nil
        }
    }
}

public enum PaymentState: String, Decodable {
    case unknown

    case pending
    case processing
    case transferred
    case successful
    case failed
}

extension PaymentState: UnknownCaseRepresentable {
    public static let unknownCase = PaymentState.unknown
}

/// line items can be added by the backend. if they refer back to a shopping cart item via their `refersTo` property, the `type` describes the relationsip
public enum LineItemType: String, Codable {
    /// not actually sent by the backend
    case unknown

    /// default item
    case `default`

    /// this item contains information about deposits, e.g. for a crate of beer
    case deposit
}

extension LineItemType: UnknownCaseRepresentable {
    public static let unknownCase = LineItemType.unknown
}

// CheckoutInfo
public struct CheckoutInfo: Decodable {
    /// available payment methods, as delivered by the API
    public let session: String
    public let availableMethods: [String]
    public let lineItems: [LineItem]
    public let price: Price

    public struct LineItem: Codable {
        public let id: String
        public let sku: String
        public let name: String
        public let amount: Int
        public let price: Int
        public let totalPrice: Int
        public let scannedCode: String?
        public let type: LineItemType
        public let refersTo: String?
    }

    public struct Price: Decodable {
        public let price: Int

        fileprivate init() {
            self.price = 0
        }
    }

    /// available and implemented payment methods
    public var paymentMethods: [RawPaymentMethod] {
        return availableMethods.compactMap { RawPaymentMethod(rawValue: $0) }
    }

    fileprivate init() {
        self.price = Price()
        self.availableMethods = [ RawPaymentMethod.encodedCodes.rawValue ]
        self.session = ""
        self.lineItems = []
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
        public let receipt: Link?
    }

    public struct PaymentInformation: Decodable {
        /// for method == .qrCode
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
        let id: String
        let sku: String
        let amount: Int
        let scannedCode: String

        let price: Int?
        let weight: Int?
        let units: Int?
        let weightUnit: Units?
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

typealias BackendCartItem = Cart.Item

/// AbortRequest
struct AbortRequest: Encodable {
    let aborted: Bool
}
