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
        self.displayName = response.truncatedcardpan
        self.expirationDate = response.cardexpiredate
    }

    var isExpired: Bool {
        #warning("FIXME")
        return false
    }
}

struct PayoneResponse {
    let status: String // = “VALID”
    let pseudocardpan: String // containing the unique pseudocardnumber (Pseudo-PAN)
    let truncatedcardpan: String // containing the masked creditcard number (masked PAN)
    let cardtype: String //  containing the selected cardtype
    let cardexpiredate: String //  containing the entered expiredate (YYMM)
    let brand: CreditCardBrand

    init(response: [[String: String]]) throws {
        #warning("implement me")
        status = "VALID"
        pseudocardpan = "123"
        truncatedcardpan = "456"
        cardtype = "VISA"
        cardexpiredate = "2103"
        brand = .visa
    }
}
