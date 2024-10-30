//
//  TeleCashCreditCardData.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public struct TeleCashCreditCardData: Codable, EncryptedPaymentData, Equatable, BrandedCreditCard {
    public let encryptedPaymentData: String
    public let serial: String
    public let displayName: String
    public let originType = AcceptedOriginType.ipgHostedDataID

    let cardHolder: String
    public let brand: CreditCardBrand
    let expirationMonth: String
    let expirationYear: String
    let version: Int
    public let projectId: Identifier<Project>?

    struct TeleCashRequestOrigin: PaymentRequestOrigin {
        // bump this when we add properties to the struct that might require invaliding previous versions
        static let version = 2

        let hostedDataID: String
        let hostedDataStoreID: String
        let cardType: String

        // new in v2
        let projectID: String
        let schemeTransactionID: String
    }

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName
        case cardHolder, brand, expirationMonth, expirationYear, version, projectId
    }

    public init?(_ response: ConnectGatewayResponse, _ projectId: Identifier<Project>, certificate: Data?) {
        guard let brand = CreditCardBrand(rawValue: response.ccBrand.lowercased()) else {
            return nil
        }

        self.version = TeleCashRequestOrigin.version
        self.displayName = response.cardNumber
        self.cardHolder = response.cardHolder
        self.brand = brand
        self.expirationYear = response.expYear
        self.expirationMonth = response.expMonth
        self.projectId = projectId

        let requestOrigin = TeleCashRequestOrigin(hostedDataID: response.hostedDataId,
                                                  hostedDataStoreID: response.storeId,
                                                  cardType: brand.cardType,
                                                  projectID: projectId.rawValue,
                                                  schemeTransactionID: response.schemeTransactionId)

        guard
            let encrypter = PaymentDataEncrypter(certificate),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encryptedPaymentData = try container.decode(String.self, forKey: .encryptedPaymentData)
        self.serial = try container.decode(String.self, forKey: .serial)
        self.displayName = try container.decode(String.self, forKey: .displayName)

        self.cardHolder = try container.decode(String.self, forKey: .cardHolder)
        self.brand = try container.decode(CreditCardBrand.self, forKey: .brand)
        self.expirationMonth = try container.decode(String.self, forKey: .expirationMonth)
        self.expirationYear = try container.decode(String.self, forKey: .expirationYear)
        let version = try container.decodeIfPresent(Int.self, forKey: .version)
        self.version = version ?? TeleCashRequestOrigin.version
        let projectId = try container.decodeIfPresent(Identifier<Project>.self, forKey: .projectId)
        self.projectId = projectId ?? ""
    }

    // the card's expiration date as a YYYY/MM/DD string with the last day of the month,
    // e.g. 2020/02/29 for expirationDate == 02/2020
    public var validUntil: String? {
        guard
            let year = Int(self.expirationYear),
            let month = Int(self.expirationMonth)
        else {
            return nil
        }

        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.year = year
        dateComponents.month = month

        guard
            let firstDate = dateComponents.date,
            let lastDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDate)
        else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/yyyy"

        return dateFormatter.string(from: lastDate)
    }

    var additionalData: [String: String] {
        var data = [
            "cardNumber": self.displayName
        ]

        if let validUntil = self.validUntil {
            data["validUntil"] = validUntil
        }

        return data
    }

    // the card's expiration date as usally displayed, e.g. 09/2020
    public var expirationDate: String {
        return "\(self.expirationMonth)/\(self.expirationYear)"
    }
    
    public var expiryDate: String? {
        return expirationDate
    }

    public var isExpired: Bool {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        guard let year = components.year, let month = components.month else {
            return false
        }

        guard let expYear = Int(self.expirationYear), let expMonth = Int(self.expirationMonth) else {
            return false
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
