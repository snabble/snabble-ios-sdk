//
//  PayOneData.swift
//  Snabble
//
//  Created by Gereon Steffens on 27.09.21.
//

import Foundation

// stores info from a PAYONE authorization
struct PayoneCreditCardData: Codable, EncryptedPaymentData, Equatable, BrandedCreditCard {
    // encrypted JSON string
    let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    let serial: String

    // name of this payment method for display in table
    var displayName: String
    let expirationDate: String

    let originType = AcceptedOriginType.payonePseudoCardPAN

    let projectId: Identifier<Project>
    let brand: CreditCardBrand

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, projectId, brand, displayName, expirationDate
    }

    private struct PayoneOrigin: PaymentRequestOrigin {
        let pseudoCardPAN: String
        let name: String
    }

    init?(gatewayCert: Data?, response: PayoneResponse, projectId: Identifier<Project>) {
        let requestOrigin = PayoneOrigin(pseudoCardPAN: "", name: "")

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

    var isExpired: Bool {
        #warning("FIXME")
        return false
    }
}

struct PayoneResponse {
    let pseudoCardPAN: String
    let maskedCardPAN: String
    let brand: CreditCardBrand
    let cardExpireDate: String // (YYMM)
    let lastName: String

    init?(response: [String: Any], lastName: String) {
        guard
            let status = response["status"] as? String,
            status == "VALID",
            let pseudoCardPAN = response["pseudocardpan"] as? String,
            let maskedCardPAN = response["truncatedcardpan"] as? String,
            let cardtype = response["cardtype"] as? String,
            let brand = CreditCardBrand.forType(cardtype),
            let cardexpiredate = response["cardexpiredate"] as? String
        else {
            return nil
        }

        self.pseudoCardPAN = pseudoCardPAN
        self.maskedCardPAN = maskedCardPAN
        self.brand = brand
        self.cardExpireDate = cardexpiredate
        self.lastName = lastName
    }
}
