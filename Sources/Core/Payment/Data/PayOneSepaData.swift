//
//  PayOneSepaData.swift
//  
//
//  Created by Uwe Tilemann on 21.11.22.
//

import Foundation

public struct PayOneSepaData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    public let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    public let serial: String

    // name of this payment method for display in table
    public var displayName: String

    public var isExpired: Bool = false
    
    public var originType = AcceptedOriginType.payoneSepaData
    
    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName
    }

    private struct DirectDebitRequestOrigin: PaymentRequestOrigin {
        let iban: String
        let lastName: String
        let city: String
        let countryCode: String
    }

    public init?(_ gatewayCert: Data?, iban: String, lastName: String, city: String, countryCode: String) {
        let requestOrigin = DirectDebitRequestOrigin(iban: iban, lastName: lastName, city: city, countryCode: countryCode)

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
