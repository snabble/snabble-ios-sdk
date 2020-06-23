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
    case paydirektCustomerAuthorization
}

// known payment methods
public enum RawPaymentMethod: String, CaseIterable, Decodable {
    case qrCodePOS              // QR Code with a reference to snabble's backend
    case qrCodeOffline          // QR Code, offline capable, format is specified via `QRCodeConfig.format`
    case deDirectDebit          // SEPA direct debit via Telecash/First Data
    case creditCardVisa         // VISA via Telecash/First Data
    case creditCardMastercard   // MASTERCARD via Telecash/First Data
    case creditCardAmericanExpress // AMERICAN EXPRESS via Telecash/First Data
    case externalBilling        // external billing, e.g. via an employee id
    case gatekeeperTerminal
    case customerCardPOS        // payment via customer card invoice
    case paydirektOneKlick

    static let orderedMethods: [RawPaymentMethod] = [
        // customer-specific methods
        .customerCardPOS, .externalBilling,

        // online methods, alphabetically
        .creditCardAmericanExpress, .creditCardMastercard, .paydirektOneKlick, .deDirectDebit, .creditCardVisa,

        // SCO / cashier
        .gatekeeperTerminal,
        .qrCodePOS, .qrCodeOffline
    ]

    /// true if this method reqires additional data, like an IBAN or a credit card number
    var dataRequired: Bool {
        switch self {
        case .deDirectDebit, .creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress,
             .externalBilling, .customerCardPOS, .paydirektOneKlick:
            return true
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal:
            return false
        }
    }

    /// true if this method can be added/edited through SDK methods
    var editable: Bool {
        switch self {
        case .deDirectDebit, .creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress, .paydirektOneKlick:
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
        case .qrCodePOS, .deDirectDebit,
             .creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress,
             .externalBilling, .gatekeeperTerminal, .customerCardPOS, .paydirektOneKlick:
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
    public let additionalData: [String: String]

    public init(_ displayName: String, _ encryptedData: String, _ originType: AcceptedOriginType, _ additionalData: [String: String]) {
        self.displayName = displayName
        self.encryptedData = encryptedData
        self.originType = originType
        self.additionalData = additionalData
    }
}

// payment method with associated data
public enum PaymentMethod {
    case qrCodePOS
    case qrCodeOffline
    case deDirectDebit(PaymentMethodData?)
    case visa(PaymentMethodData?)
    case mastercard(PaymentMethodData?)
    case americanExpress(PaymentMethodData?)
    case externalBilling(PaymentMethodData?)
    case gatekeeperTerminal
    case customerCardPOS
    case paydirektOneKlick(PaymentMethodData?)

    public var rawMethod: RawPaymentMethod {
        switch self {
        case .qrCodePOS: return .qrCodePOS
        case .qrCodeOffline: return .qrCodeOffline
        case .deDirectDebit: return .deDirectDebit
        case .visa: return .creditCardVisa
        case .mastercard: return .creditCardMastercard
        case .americanExpress: return .creditCardAmericanExpress
        case .externalBilling: return .externalBilling
        case .gatekeeperTerminal: return .gatekeeperTerminal
        case .customerCardPOS: return .customerCardPOS
        case .paydirektOneKlick: return .paydirektOneKlick
        }
    }

    public var data: PaymentMethodData? {
        switch self {
        case .deDirectDebit(let data), .visa(let data), .mastercard(let data), .americanExpress(let data):
            return data
        case .externalBilling(let data):
            return data
        case .paydirektOneKlick(let data):
            return data
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal, .customerCardPOS:
            return nil
        }
    }

    public var additionalData: [String: String] {
        switch self {
        case .visa(let data), .mastercard(let data), .americanExpress(let data), .paydirektOneKlick(let data):
            return data?.additionalData ?? [:]
        case .deDirectDebit, .qrCodePOS, .qrCodeOffline, .externalBilling, .gatekeeperTerminal, .customerCardPOS:
            return [:]
        }
    }
}

public enum PaymentState: String, Decodable, UnknownCaseRepresentable {
    case unknown

    case pending
    case processing
    case transferred
    case successful
    case failed

    public static let unknownCase = PaymentState.unknown
}

/// line items can be added by the backend.
/// If they refer back to a shopping cart item via their `refersTo` property, the `type` describes the relationship
public enum LineItemType: String, Codable, UnknownCaseRepresentable {
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
        public let weight: Int?
        public let units: Int?
        public let totalPrice: Int?
        public let scannedCode: String?
        public let type: LineItemType
        public let refersTo: String?
        public let fulfillmentType: String?
        public let weightUnit: Units?
        public let referenceUnit: Units?

        /// price pre-multiplied with units, if present
        public var itemPrice: Int? {
            guard let price = self.price else {
                return nil
            }
            return (self.units ?? 1) * price
        }
    }

    public struct Price: Decodable {
        public let price: Int
        public let netPrice: Int

        fileprivate init() {
            self.price = 0
            self.netPrice = 0
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

// MARK: - process checks
public enum CheckState: String, Codable, UnknownCaseRepresentable {
    case unknown

    case pending
    case successful
    case failed

    public static let unknownCase = CheckState.unknown
}

public enum CheckType: String, Codable {
    case minAge = "min_age"
}

public struct CheckoutCheck: Decodable {
    public let id: String
    public let links: CheckLinks

    public let state: CheckState
    public let type: CheckType

    // type-specific properties
    public let requiredAge: Int? // set for min_age

    public struct CheckLinks: Decodable {
        public let `self`: Link
    }
}

public enum FulfillmentState: String, Decodable, UnknownCaseRepresentable {
    case unknown

    // working
    case open, allocating, allocated, processing
    // finished successfully
    case processed
    // finished with error
    case aborted, allocationFailed, allocationTimedOut, failed

    static let workingStates: Set<FulfillmentState> = [ .open, .allocating, .allocated, .processing ]
    static let failureStates: Set<FulfillmentState> = [ .aborted, .allocationFailed, .allocationTimedOut, .failed ]

    static let endStates: Set<FulfillmentState> = [ .processed, .aborted, .allocationFailed, .allocationTimedOut, .failed ]

    public static let unknownCase = FulfillmentState.unknown
}

public struct Fulfillment: Decodable {
    public let id: String
    public let refersTo: [String]
    public let type: String
    public let state: FulfillmentState
    public let errors: [FulfillmentError]?

    public struct FulfillmentError: Decodable {
        public let type: String
        public let refersTo: String?
        public let message: String
    }
}

public struct AgeCheckData: Encodable {
    public let requiredAge: Int
    public let state: CheckState
    public let type: CheckType
    public let dayOfBirth: String // YYYY/MM/DD
}

// MARK: - Checkout Process
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
    public let paymentResult: [String: Any]?
    public let pricing: Pricing
    public let checks: [CheckoutCheck]
    public let fulfillments: [Fulfillment]

    public struct Pricing: Decodable {
        public let lineItems: [CheckoutInfo.LineItem]
    }

    public struct ProcessLinks: Decodable {
        public let `self`: Link
        public let approval: Link
        public let receipt: Link?
    }

    public struct PaymentInformation: Decodable {
        /// for method == .qrCodePOS
        public let qrCodeContent: String?
    }

    enum CodingKeys: String, CodingKey {
        case links, supervisorApproval, paymentApproval, aborted
        case checkoutInfo, paymentMethod, modified, paymentInformation
        case paymentState, orderID, paymentResult
        case checks, fulfillments, pricing
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.links = try container.decode(ProcessLinks.self, forKey: .links)
        self.supervisorApproval = try container.decodeIfPresent(Bool.self, forKey: .supervisorApproval)
        self.paymentApproval = try container.decodeIfPresent(Bool.self, forKey: .paymentApproval)
        self.aborted = try container.decode(Bool.self, forKey: .aborted)
        self.checkoutInfo = try container.decode(CheckoutInfo.self, forKey: .checkoutInfo)
        self.paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
        self.modified = try container.decode(Bool.self, forKey: .modified)
        self.paymentInformation = try container.decodeIfPresent(PaymentInformation.self, forKey: .paymentInformation)
        self.paymentState = try container.decode(PaymentState.self, forKey: .paymentState)
        self.orderID = try container.decodeIfPresent(String.self, forKey: .orderID)
        self.paymentResult = try container.decodeIfPresent([String: Any].self, forKey: .paymentResult)
        self.pricing = try container.decode(Pricing.self, forKey: .pricing)

        let rawChecks = try container.decodeIfPresent([FailableDecodable<CheckoutCheck>].self, forKey: .checks)
        let checks = rawChecks?.compactMap { $0.value } ?? []
        self.checks = checks.filter { $0.state != .unknown }

        let rawFulfillments = try container.decodeIfPresent([FailableDecodable<Fulfillment>].self, forKey: .fulfillments)
        let fulfillments = rawFulfillments?.compactMap { $0.value } ?? []
        self.fulfillments = fulfillments.filter { $0.state != .unknown }
    }

    func fulfillmentsDone() -> Bool {
        let states = self.fulfillments.map { $0.state }
        return Set(states).isDisjoint(with: FulfillmentState.workingStates)
    }
}

// MARK: - data we send to the server

/// Cart
public struct Cart: Encodable {
    let session: String
    let shopID: String
    let customer: CustomerInfo?
    let items: [Item]
    let clientID: String
    let appUserID: String?

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

public enum CandidateType: String, Decodable {
    case debitCardIban = "debit_card_iban"
}

public struct OriginCandidate: Decodable {
    public let links: CandidateLinks?
    public let origin: String?
    public let type: CandidateType?

    public struct CandidateLinks: Decodable {
        public let `self`: Link
        public let promote: Link
    }

    public var isValid: Bool {
        return self.links?.promote != nil && self.origin != nil && self.type != nil
    }
}
