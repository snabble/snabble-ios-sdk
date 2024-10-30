//
//  SepaData.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public struct SepaData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    public let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    public let serial: String

    // name of this payment method for display in table
    public let displayName: String

    public let originType = AcceptedOriginType.iban

    public let isExpired = false
    public let validUntil: String? = nil

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName
    }

    private struct DirectDebitRequestOrigin: PaymentRequestOrigin {
        let name: String
        let iban: String
    }

    public init?(_ gatewayCert: Data?, _ name: String, _ iban: String) {
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
