//
//  LeinweberCustomerData.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

struct LeinweberCustomerData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    let serial: String

    // name of this payment method for display in table
    let displayName: String

    let isExpired = false

    let originType = AcceptedOriginType.leinweberCustomerID

    let cardNumber: String

    let projectId: Identifier<Project>

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName, cardNumber, projectId
    }

    private struct CardNumberOrigin: PaymentRequestOrigin {
        let cardNumber: String
    }

    init?(_ gatewayCert: Data?, _ number: String, _ name: String, _ projectId: Identifier<Project>) {
        let requestOrigin = CardNumberOrigin(cardNumber: number)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial

        self.displayName = name
        self.cardNumber = number
        self.projectId = projectId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encryptedPaymentData = try container.decode(String.self, forKey: .encryptedPaymentData)
        self.serial = try container.decode(String.self, forKey: .serial)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.cardNumber = (try? container.decodeIfPresent(String.self, forKey: .cardNumber)) ?? ""
        let projectId = try container.decodeIfPresent(Identifier<Project>.self, forKey: .projectId)
        self.projectId = projectId ?? ""
    }
}
