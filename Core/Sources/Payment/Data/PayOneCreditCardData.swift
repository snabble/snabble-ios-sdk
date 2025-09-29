//
//  PayOneData.swift
//  Snabble
//
//  Created by Gereon Steffens on 27.09.21.
//

import Foundation

// stores info from a PAYONE authorization
public struct PayoneCreditCardData: Codable, EncryptedPaymentData, Equatable, BrandedCreditCard {
    // encrypted JSON string
    public let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    public let serial: String

    // name of this payment method for display in table
    public var displayName: String
    public let expirationDate: String // as "MM/YY"

    public let originType = AcceptedOriginType.payonePseudoCardPAN

    public let projectId: Identifier<Project>
    public let brand: CreditCardBrand

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, projectId, brand, displayName, expirationDate
    }

    private struct PayoneOrigin: PaymentRequestOrigin {
        let userID: String
        let pseudoCardPAN: String
        let name: String
        let email: String
        let address: Address
        
        struct Address: Encodable {
            let street: String
            let zip: String
            let city: String
            let country: String
            let state: String?
        }
        
        init(userID: String, info: PayonePreAuthData) {
            self.userID = userID
            self.pseudoCardPAN = info.pseudoCardPAN
            self.name = info.lastname
            self.email = info.email
            self.address = Address(street: info.address.street,
                                   zip: info.address.zip,
                                   city: info.address.city,
                                   country: info.address.country,
                                   state: info.address.state)
        }
    }

    public init?(gatewayCert: Data?, response: PayoneResponse, preAuthResult: PayonePreAuthResult, projectId: Identifier<Project>) {
        let requestOrigin = PayoneOrigin(userID: preAuthResult.userID, info: response.info)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.brand = response.brand
        self.projectId = projectId
        self.encryptedPaymentData = cipherText
        self.serial = serial
        self.displayName = response.maskedCardPAN
        self.expirationDate = response.cardExpireDate
    }

    public var isExpired: Bool {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        guard let year = components.year, let month = components.month else {
            return false
        }

        guard
            var expYear = Int(String(self.expirationDate.suffix(2))),
            let expMonth = Int(String(self.expirationDate.prefix(2)))
        else {
            return false
        }

        expYear += 2000
        if year > expYear {
            return true
        } else if year == expYear && month > expMonth {
            return true
        } else {
            return false
        }
    }
    
    public var validUntil: String? {
        "\(self.expirationDate.prefix(2))/20\(self.expirationDate.suffix(2))"
    }
}

public struct PayoneResponse: Sendable {
    public let info: PayonePreAuthData
    let maskedCardPAN: String
    let brand: CreditCardBrand
    let cardExpireDate: String // MM/YY

    public init?(response: [String: Any], info: PayonePreAuthData) {
        guard
            let status = response["status"] as? String,
            status == "VALID",
            let maskedCardPAN = response["truncatedcardpan"] as? String,
            let cardtype = response["cardtype"] as? String,
            let brand = CreditCardBrand.forType(cardtype),
            let cardexpiredate = response["cardexpiredate"] as? String
        else {
            return nil
        }

        self.maskedCardPAN = maskedCardPAN
        self.brand = brand
        self.info = info

        // raw cardexpiredate is YYMM, convert to MM/YY
        self.cardExpireDate = cardexpiredate.suffix(2) + "/" + cardexpiredate.prefix(2)
    }
}
