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
        let userID: String
    }

    init?(gatewayCert: Data?, response: PayoneResponse, preAuthResult: PayonePreAuthResult, projectId: Identifier<Project>) {
        let requestOrigin = PayoneOrigin(pseudoCardPAN: response.pseudoCardPAN, name: response.lastname, userID: preAuthResult.userID)

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
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        guard let year = components.year, let month = components.month else {
            return false
        }

        guard
            let expYear = Int(String(self.expirationDate.prefix(2))),
            let expMonth = Int(String(self.expirationDate.suffix(2)))
        else {
            return false
        }

        if year > 2000 + expYear {
            return true
        } else if month > expMonth {
            return true
        } else {
            return false
        }
    }
}

struct PayoneResponse {
    let pseudoCardPAN: String
    let maskedCardPAN: String
    let brand: CreditCardBrand
    let cardExpireDate: String // (YYMM)
    let lastname: String

    init?(response: [String: Any], lastname: String) {
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
        self.lastname = lastname

        // cardexpiredate is YYMM, convert to MM/YY
        self.cardExpireDate = cardexpiredate.suffix(2) + "/" + cardexpiredate.prefix(2)
    }
}
