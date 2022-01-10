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
    case datatransAlias
    case datatransCreditCardAlias
    case payonePseudoCardPAN
    case leinweberCustomerID
}

public enum PaymentState: String, Decodable, UnknownCaseRepresentable {
    case unknown

    case pending
    case processing
    case transferred
    case successful
    case failed
    case unauthorized

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

    /// a coupon
    case coupon

    public static let unknownCase = LineItemType.unknown
}

// optional required information
public struct RequiredInformation: Codable {
    public let id: RequiredInformationType
    public let value: String?

    enum TaxationValue: String {
        case inHouse
        case takeaway
    }

    static let taxationInhouse = RequiredInformation(id: .taxation, value: TaxationValue.inHouse.rawValue)
    static let taxationTakeaway = RequiredInformation(id: .taxation, value: TaxationValue.takeaway.rawValue)
}

public enum RequiredInformationType: String, Codable {
    case taxation
}

// CheckoutInfo
public struct CheckoutInfo: Decodable {
    /// session id
    public let session: String

    /// available payment methods
    public let paymentMethods: [PaymentMethodDescription]

    /// line items (only contains records with supported types)
    public let lineItems: [LineItem]

    /// optional: required information for the checkout, e.g. inhouse or takeaway
    public let requiredInformation: [RequiredInformation]

    /// price info
    public let price: Price

    enum CodingKeys: String, CodingKey {
        case session, paymentMethods, lineItems, price, requiredInformation
    }

    public struct LineItem: Codable {
        public let id: String
        public let sku: String?
        public let name: String?
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
        public let priceModifiers: [PriceModifier]?
        public let couponID: String?
        public let redeemed: Bool?

        /// price pre-multiplied with units, if present
        public var itemPrice: Int? {
            guard let price = self.price else {
                return nil
            }
            return (self.units ?? 1) * price
        }

        public struct PriceModifier: Codable {
            let name: String
            let price: Int
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
        self.requiredInformation = try container.decodeIfPresent([RequiredInformation].self, forKey: .requiredInformation) ?? []
    }

    fileprivate init(_ paymentMethods: [RawPaymentMethod]) {
        self.price = Price()
        self.paymentMethods = paymentMethods.map { PaymentMethodDescription(method: $0, acceptedOriginTypes: nil) }
        self.session = ""
        self.lineItems = []
        self.requiredInformation = []
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

    public static let workingStates: Set<FulfillmentState> =
        [ .open, .allocating, .allocated, .processing ]
    public static let failureStates: Set<FulfillmentState> =
        [ .aborted, .allocationFailed, .allocationTimedOut, .failed ]
    public static let endStates: Set<FulfillmentState> =
        [ .aborted, .allocationFailed, .allocationTimedOut, .failed, .processed ]

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

// known values from checkoutProcess.paymentResults["failureCause"]
public enum FailureCause: String {
    case terminalAbort
    case ageVerificationFailed
    case ageVerificationNotSupportedByCard
}

public struct ExitToken: Codable {
    public let format: ScanFormat?
    public let value: String?
}

public enum RoutingTarget: String, Decodable, UnknownCaseRepresentable {
    case none
    case supervisor
    case gatekeeper

    public static let unknownCase = Self.none
}

// MARK: - Checkout Process
public struct CheckoutProcess: Decodable {
    public let id: String
    public let links: ProcessLinks
    @available(*, deprecated)
    public let supervisorApproval: Bool?
    @available(*, deprecated)
    public let paymentApproval: Bool?
    public let aborted: Bool
    public let paymentMethod: String
    public let modified: Bool
    public let paymentInformation: PaymentInformation?
    public let paymentState: PaymentState
    public let orderID: String?
    public let paymentResult: [String: Any]?
    public let pricing: Pricing
    public let checks: [CheckoutProcess.Check]
    public let fulfillments: [Fulfillment]
    public let exitToken: ExitToken?
    public let currency: String
    public let paymentPreauthInformation: PaymentPreauthInformation?
    public let routingTarget: RoutingTarget

    public var rawPaymentMethod: RawPaymentMethod? {
        RawPaymentMethod(rawValue: paymentMethod)
    }

    public struct Pricing: Decodable {
        public let lineItems: [CheckoutInfo.LineItem]
        public let price: CheckoutInfo.Price
    }

    public struct ProcessLinks: Decodable {
        public let `self`: Link
        public let approval: Link
        public let receipt: Link?
        public let authorizePayment: Link? // for Apple Pay, POST the transaction payload to this URL
    }

    public struct PaymentInformation: Decodable {
        /// for method == .qrCodePOS
        public let qrCodeContent: String?
    }

    public struct PaymentPreauthInformation: Decodable {
        public let merchantID: String? // for Apple Pay
    }

    enum CodingKeys: String, CodingKey {
        case id
        case links, supervisorApproval, paymentApproval, aborted
        case checkoutInfo, paymentMethod, modified, paymentInformation
        case paymentState, orderID, paymentResult
        case checks, fulfillments, pricing, exitToken
        case currency, paymentPreauthInformation
        case routingTarget
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.links = try container.decode(ProcessLinks.self, forKey: .links)
        self.supervisorApproval = try container.decodeIfPresent(Bool.self, forKey: .supervisorApproval)
        self.paymentApproval = try container.decodeIfPresent(Bool.self, forKey: .paymentApproval)
        self.aborted = try container.decode(Bool.self, forKey: .aborted)
        self.paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
        self.modified = try container.decode(Bool.self, forKey: .modified)
        self.paymentInformation = try container.decodeIfPresent(PaymentInformation.self, forKey: .paymentInformation)
        self.paymentState = try container.decode(PaymentState.self, forKey: .paymentState)
        self.orderID = try container.decodeIfPresent(String.self, forKey: .orderID)
        self.paymentResult = try container.decodeIfPresent([String: Any].self, forKey: .paymentResult)
        self.pricing = try container.decode(Pricing.self, forKey: .pricing)

        let rawChecks = try container.decodeIfPresent([FailableDecodable<CheckoutProcess.Check>].self, forKey: .checks)
        let checks = rawChecks?.compactMap { $0.value } ?? []
        self.checks = checks.filter { $0.state != .unknown }

        let rawFulfillments = try container.decodeIfPresent([FailableDecodable<Fulfillment>].self, forKey: .fulfillments)
        let fulfillments = rawFulfillments?.compactMap { $0.value } ?? []
        self.fulfillments = fulfillments.filter { $0.state != .unknown }
        self.exitToken = try container.decodeIfPresent(ExitToken.self, forKey: .exitToken)

        self.currency = try container.decode(String.self, forKey: .currency)
        self.paymentPreauthInformation = try container.decodeIfPresent(PaymentPreauthInformation.self, forKey: .paymentPreauthInformation)
        self.routingTarget = try container.decode(RoutingTarget.self, forKey: .routingTarget)
    }

    var requiresExitToken: Bool {
        exitToken != nil
    }
}

// MARK: - Fulfillment convenience methods
extension CheckoutProcess {
    /// Check if all fulfillments are done
    /// - Returns: true if all fulfillments are done
    public func fulfillmentsDone() -> Bool {
        let states = self.fulfillments.map { $0.state }
        return Set(states).isDisjoint(with: FulfillmentState.workingStates)
    }

    /// Number of failed fulfillments
    /// - Returns: number of failed fulfillments
    public func fulfillmentsFailed() -> Int {
        let states = self.fulfillments.map { $0.state }
        return states.filter { FulfillmentState.failureStates.contains($0) }.count
    }

    /// Number of fulfillments currently in progress
    /// - Returns: number of fulfillments currently in progress
    public func fulfillmentsInProgress() -> Int {
        let states = self.fulfillments.map { $0.state }
        return states.filter { FulfillmentState.workingStates.contains($0) }.count
    }

    /// Number of successful fulfillments
    /// - Returns: number of successful fulfillments
    public func fulfillmentsSucceeded() -> Int {
        let states = self.fulfillments.map { $0.state }
        return states.filter { $0 == .processed }.count
    }
}

// MARK: - data we send to the server

/// Cart
public struct Cart: Encodable {
    public let session: String
    public let shopID: Identifier<Shop>
    public let customer: CustomerInfo?
    public let items: [Item]
    public let clientID: String
    public let appUserID: String?
    public let requiredInformation: [RequiredInformation]

    init(_ cart: ShoppingCart, clientId: String, appUserId: String?) {
        self.session = cart.session
        self.shopID = cart.shopId
        self.customer = Cart.CustomerInfo(loyaltyCard: cart.customerCard)
        self.items = cart.backendItems()
        self.requiredInformation = cart.requiredInformationData

        self.clientID = clientId
        self.appUserID = appUserId
    }

    public enum Item: Encodable {
        case product(ProductItem)
        case coupon(CouponItem)

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .product(let productItem):
                try container.encode(productItem)
            case .coupon(let couponItem):
                try container.encode(couponItem)
            }
        }
    }

    public struct ProductItem: Encodable {
        public let id: String
        public let sku: String
        public let amount: Int
        public let scannedCode: String

        public let price: Int?
        public let weight: Int?
        public let units: Int?
        public let weightUnit: Units?
    }

    public struct CouponItem: Encodable {
        public let id: String
        public let couponID: String
        public let refersTo: String?
        public let scannedCode: String?
        public let amount: Int

        init(couponId: String, refersTo: String? = nil, scannedCode: String? = nil, amount: Int = 1) {
            self.id = UUID().uuidString
            self.couponID = couponId
            self.refersTo = refersTo
            self.scannedCode = scannedCode
            self.amount = amount
        }
    }

    public struct CustomerInfo: Encodable {
        public let loyaltyCard: String

        init?(loyaltyCard: String?) {
            guard let card = loyaltyCard else {
                return nil
            }
            self.loyaltyCard = card
        }
    }
}

/// AbortRequest
struct AbortRequest: Encodable {
    let aborted: Bool
}

public enum CandidateType: String, Decodable, Hashable {
    case debitCardIban = "debit_card_iban"
}

public struct OriginCandidate: Decodable {
    public let links: CandidateLinks?
    public let origin: String?
    public let type: CandidateType?

    public struct CandidateLinks: Decodable, Hashable {
        public let `self`: Link
        public let promote: Link
    }

    public var isValid: Bool {
        return self.links?.promote != nil && self.origin != nil && self.type != nil
    }
}

extension OriginCandidate: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(links?.`self`)
        hasher.combine(type)
    }
}
