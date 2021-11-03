//
//  DatatransData.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

struct DatatransPaymentMethodToken: Codable, Equatable {
    let token: String
    let displayTitle: String
    let cardHolder: String?
    let expirationMonth: String?
    let expirationYear: String?

    init(token: String, displayTitle: String, cardHolder: String?, expirationMonth: String?, expirationYear: String?) {
        self.token = token
        self.displayTitle = displayTitle
        self.cardHolder = cardHolder
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
    }

    // the card's expiration date as usally displayed, e.g. 09/2020
    var expirationDate: String? {
        guard let expYear = expirationYear, let expMonth = expirationMonth else {
            return nil
        }

        return "\(expMonth)/\(expYear)"
    }

    var isExpired: Bool {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        guard let year = components.year, let month = components.month else {
            return false
        }

        guard
            var expYear = Int(self.expirationYear ?? ""),
            let expMonth = Int(self.expirationMonth ?? "") else {
            return false
        }

        // expYear only has two digits
        if expYear < 100 {
            expYear += 2000
        }

        if year > expYear {
            return true
        } else if year == expYear && month > expMonth {
            return true
        } else {
            return false
        }
    }
}

enum DatatransMethod: String, Codable {
    case twint
    case postFinanceCard

    var rawMethod: RawPaymentMethod {
        switch self {
        case .twint: return .twint
        case .postFinanceCard: return .postFinanceCard
        }
    }
}

extension RawPaymentMethod {
    var datatransMethod: DatatransMethod? {
        switch self {
        case .twint: return .twint
        case .postFinanceCard: return .postFinanceCard
        default: return nil
        }
    }
}

// Usable for TWINT / PostFinance Card
// - stores info from a plain Datatrans.PaymentMethodToken, with optional expiry date
struct DatatransData: Codable, EncryptedPaymentData, Equatable {
    static func == (lhs: DatatransData, rhs: DatatransData) -> Bool {
        return true
    }

    // encrypted JSON string
    let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    let serial: String

    // name of this payment method for display in table
    var displayName: String { token.displayTitle }

    let originType = AcceptedOriginType.datatransAlias

    let projectId: Identifier<Project>
    let method: DatatransMethod
    let token: DatatransPaymentMethodToken

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, projectId, method, token
    }

    private struct DatatransOrigin: PaymentRequestOrigin {
        let alias: String
    }

    init?(gatewayCert: Data?, method: DatatransMethod, token: DatatransPaymentMethodToken, projectId: Identifier<Project>) {
        let requestOrigin = DatatransOrigin(alias: token.token)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.method = method
        self.projectId = projectId
        self.encryptedPaymentData = cipherText
        self.serial = serial
        self.token = token
    }

    var isExpired: Bool { token.isExpired }

    var expirationDate: String? { token.expirationDate }
}

// Usable for Credit Cards
// - stores info from a Datatrans.CardToken
struct DatatransCreditCardData: Codable, EncryptedPaymentData, Equatable, BrandedCreditCard {
    // encrypted JSON string
    let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    let serial: String

    // name of this payment method for display in table
    var displayName: String { token.displayTitle }

    let originType = AcceptedOriginType.datatransCreditCardAlias

    let projectId: Identifier<Project>
    let brand: CreditCardBrand
    let token: DatatransPaymentMethodToken

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, projectId, brand, token
    }

    private struct DatatransCreditCardOrigin: PaymentRequestOrigin {
        let alias: String
        let expiryMonth: String? // 2-digit month
        let expiryYear: String? // 2-digit year
    }

    init?(gatewayCert: Data?, brand: CreditCardBrand, token: DatatransPaymentMethodToken, projectId: Identifier<Project>) {
        let requestOrigin = DatatransCreditCardOrigin(alias: token.token,
                                                      expiryMonth: token.expirationMonth,
                                                      expiryYear: token.expirationYear)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.brand = brand
        self.projectId = projectId
        self.encryptedPaymentData = cipherText
        self.serial = serial
        self.token = token
    }

    var isExpired: Bool { token.isExpired }

    var expirationDate: String? { token.expirationDate }
}
