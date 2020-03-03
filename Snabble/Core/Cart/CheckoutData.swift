//
//  CheckoutData.swift
//
//  Copyright © 2020 snabble. All rights reserved.
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
    var rawJson: [String: Any]?

    // only used for the embedded codes offline payment
    init(_ paymentMethods: [RawPaymentMethod]) {
        self.checkoutInfo = CheckoutInfo(paymentMethods)
        self.signature = ""
        self.links = CheckoutLinks()
    }
}

public enum AcceptedOriginType: String, Codable {
    case iban
    case ipgHostedDataID
    case tegutEmployeeID
}

// known payment methods
public enum RawPaymentMethod: String, CaseIterable, Decodable {
    case qrCodePOS              // QR Code with a reference to snabble's backend
    case qrCodeOffline          // QR Code, offline capable, format is specified via `QRCodeConfig.format`
    case deDirectDebit          // SEPA direct debit via Telecash/First Data
    case creditCardVisa         // VISA via Telecash/First Data
    case creditCardMastercard   // MASTERCARD via Telecash/First Data
    case externalBilling        // external billig, e.g. via an employee id
    case gatekeeperTerminal
    case customerCardPOS        // payment via customer card invoice

    /// true if this method reqires additional data, like an IBAN or a credit card number
    var dataRequired: Bool {
        switch self {
        case .deDirectDebit, .creditCardVisa, .creditCardMastercard, .externalBilling, .customerCardPOS:
            return true
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal:
            return false
        }
    }

    /// true if this method can be added/edited through SDK methods
    var editable: Bool {
        switch self {
        case .deDirectDebit, .creditCardVisa, .creditCardMastercard:
            return true
        case .qrCodePOS, .qrCodeOffline, .externalBilling, .gatekeeperTerminal, .customerCardPOS:
            return false
        }
    }

    /// true if this method can be used even if creating a checkout info/process fails
    public var offline: Bool {
        switch self {
        case .qrCodeOffline:
            return true
        case .qrCodePOS, .deDirectDebit, .creditCardVisa,
             .creditCardMastercard, .externalBilling,
             .gatekeeperTerminal, .customerCardPOS:
            return false
        }
    }
}

public struct PaymentMethodDescription: Decodable {

    enum CodingKeys: String, CodingKey {
        case method = "id"
        case acceptedOriginTypes
    }

    public let method: RawPaymentMethod
    public let acceptedOriginTypes: [AcceptedOriginType]?
}

// associated data for a payment method
public struct PaymentMethodData {
    public let displayName: String
    public let encryptedData: String
    public let originType: AcceptedOriginType

    public init(_ displayName: String, _ encryptedData: String, _ originType: AcceptedOriginType) {
        self.displayName = displayName
        self.encryptedData = encryptedData
        self.originType = originType
    }
}

// payment method with associated data
public enum PaymentMethod {
    case qrCodePOS
    case qrCodeOffline
    case deDirectDebit(PaymentMethodData?)
    case visa(PaymentMethodData?)
    case mastercard(PaymentMethodData?)
    case externalBilling(PaymentMethodData?)
    case gatekeeperTerminal
    case customerCardPOS

    public var rawMethod: RawPaymentMethod {
        switch self {
        case .qrCodePOS: return .qrCodePOS
        case .qrCodeOffline: return .qrCodeOffline
        case .deDirectDebit: return .deDirectDebit
        case .visa: return .creditCardVisa
        case .mastercard: return .creditCardMastercard
        case .externalBilling: return .externalBilling
        case .gatekeeperTerminal: return .gatekeeperTerminal
        case .customerCardPOS: return .customerCardPOS
        }
    }

    public var data: PaymentMethodData? {
        switch self {
        case .deDirectDebit(let data), .visa(let data), .mastercard(let data):
            return data
        case .externalBilling(let data):
            return data
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal, .customerCardPOS:
            return nil
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

    /// a price-reducing promotion like "1 € off"
    case discount

    /// a giveaway product that is automatically added
    case giveaway
}

extension LineItemType: UnknownCaseRepresentable {
    public static let unknownCase = LineItemType.unknown
}

// CheckoutInfo
public struct CheckoutInfo: Decodable {
    /// session id
    public let session: String

    /// available payment methods
    public let paymentMethods: [PaymentMethodDescription]

    /// line items (only contains records with supported types)
    public let lineItems: [LineItem]

    /// price info
    public let price: Price

    enum CodingKeys: String, CodingKey {
        case session, paymentMethods, lineItems, price
    }

    public struct LineItem: Codable {
        public let id: String
        public let sku: String
        public let name: String
        public let amount: Int
        public let price: Int?
        public let totalPrice: Int?
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.session = try container.decode(String.self, forKey: .session)
        let paymentMethods = try container.decode([FailableDecodable<PaymentMethodDescription>].self, forKey: .paymentMethods)
        self.paymentMethods = paymentMethods.compactMap { $0.value }
        let lineItems = try container.decode([LineItem].self, forKey: .lineItems)
        self.lineItems = lineItems.filter { $0.type != .unknown }
        self.price = try container.decode(Price.self, forKey: .price)
    }

    fileprivate init(_ paymentMethods: [RawPaymentMethod]) {
        self.price = Price()
        self.paymentMethods = paymentMethods.map { PaymentMethodDescription(method: $0, acceptedOriginTypes: nil) }
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
    public let orderID: String?

    public struct ProcessLinks: Decodable {
        public let `self`: Link
        public let approval: Link
        public let receipt: Link?
    }

    public struct PaymentInformation: Decodable {
        /// for method == .qrCodePOS
        public let qrCodeContent: String?
    }
}

// MARK: - data we send to the server

/// Cart
public struct Cart: Encodable {
    let session: String
    let shopID: String
    let customer: CustomerInfo?
    let items: [Item]

    public struct Item: Encodable {
        let id: String
        let sku: String
        public let amount: Int
        public let scannedCode: String

        let price: Int?
        let weight: Int?
        let units: Int?
        let weightUnit: Units?
    }

    struct CustomerInfo: Encodable {
        let loyaltyCard: String

        init?(loyaltyCard: String?) {
            guard let card = loyaltyCard else {
                return nil
            }
            self.loyaltyCard = card
        }
    }
}

public typealias BackendCartItem = Cart.Item

/// AbortRequest
struct AbortRequest: Encodable {
    let aborted: Bool
}
