//
//  SepaData.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

struct SepaData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    let serial: String

    // name of this payment method for display in table
    let displayName: String

    let originType = AcceptedOriginType.iban

    let isExpired = false

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName
    }

    private struct DirectDebitRequestOrigin: PaymentRequestOrigin {
        let name: String
        let iban: String
    }

    init?(_ gatewayCert: Data?, _ name: String, _ iban: String) {
        let requestOrigin = DirectDebitRequestOrigin(name: name, iban: iban)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial

        self.displayName = IBAN.displayName(iban)
    }
}
