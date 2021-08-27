//
//  PaymentMethods.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

public struct PaymentMethodDescriptor: Decodable {
    public let id: RawPaymentMethod
    public let acceptedOriginTypes: [AcceptedOriginType]?
    public let links: Links?

    public struct Links: Decodable {
        public let tokenization: Link?
    }
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
    case applePay
    case postFinanceCard        // via Datatrans
    case twint                  // via Datatrans

    static let orderedMethods: [RawPaymentMethod] = [
        // customer-specific methods
        .customerCardPOS, .externalBilling,

        // online methods, alphabetically
        .creditCardAmericanExpress, .applePay,
        .creditCardMastercard, .paydirektOneKlick,
        .postFinanceCard, .deDirectDebit,
        .twint, .creditCardVisa,

        // SCO / cashier
        .gatekeeperTerminal,
        .qrCodePOS, .qrCodeOffline
    ]

    // roughly sorted by popularity
    // Apple Pay is not included here, needs separate treatment
    static let preferredOnlineMethods: [RawPaymentMethod] = [
        .deDirectDebit, .creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress, .paydirektOneKlick
    ]

    /// true if this method reqires additional data, like an IBAN or a credit card number
    var dataRequired: Bool {
        switch self {
        case .deDirectDebit, .creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress,
             .externalBilling, .customerCardPOS, .paydirektOneKlick, .twint, .postFinanceCard:
            return true
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal, .applePay:
            return false
        }
    }

    /// true if this method is shown/edited on the PaymentMethod[Add|List]ViewControllers
    public var editable: Bool {
        switch self {
        case .deDirectDebit, .paydirektOneKlick,
             .creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress,
             .twint, .postFinanceCard:
            return true
        case .qrCodePOS, .externalBilling, .qrCodeOffline, .gatekeeperTerminal, .customerCardPOS, .applePay:
            return false
        }
    }

    /// true if editing/entering this method requires a device passcode or biometry
    var codeRequired: Bool {
        switch self {
        case .deDirectDebit, .creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress, .paydirektOneKlick,
             .twint, .postFinanceCard:
            return true
        case .qrCodePOS, .qrCodeOffline, .externalBilling, .gatekeeperTerminal, .customerCardPOS, .applePay:
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
             .externalBilling, .gatekeeperTerminal, .customerCardPOS, .paydirektOneKlick,
             .applePay, .twint, .postFinanceCard:
            return false
        }
    }

    /// true if this method needs a plugin (e.g. the Snabble/Datatrans module)
    public var needsPlugin: Bool {
        switch self {
        case .twint, .postFinanceCard:
            return true
        case .qrCodeOffline, .qrCodePOS, .deDirectDebit,
             .creditCardVisa, .creditCardMastercard, .creditCardAmericanExpress,
             .externalBilling, .gatekeeperTerminal, .customerCardPOS, .paydirektOneKlick,
             .applePay:
            return false
        }
    }

    // true if this method is available for use - shortcut for the registry method call
    public var isAvailable: Bool {
        return SnabbleAPI.methodRegistry.isMethodAvailable(self)
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
    case applePay
    case twint(PaymentMethodData?)
    case postFinanceCard(PaymentMethodData?)

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
        case .applePay: return .applePay
        case .twint: return .twint
        case .postFinanceCard: return .postFinanceCard
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
        case .twint(let data):
            return data
        case .postFinanceCard(let data):
            return data
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal, .customerCardPOS, .applePay:
            return nil
        }
    }

    public var additionalData: [String: String] {
        switch self {
        case .visa(let data), .mastercard(let data), .americanExpress(let data), .paydirektOneKlick(let data):
            return data?.additionalData ?? [:]
        case .deDirectDebit, .qrCodePOS, .qrCodeOffline, .externalBilling, .gatekeeperTerminal, .customerCardPOS,
             .applePay, .twint, .postFinanceCard:
            return [:]
        }
    }
}
