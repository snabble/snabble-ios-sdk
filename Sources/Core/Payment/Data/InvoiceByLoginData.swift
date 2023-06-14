//
//  InvoiceByLoginData.swift
//
//  Created by Uwe Tilemann on 01.06.23.
//

import Foundation

public struct InvoiceByLoginData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    public let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    public let serial: String

    // name of this payment method for display in table
    public let displayName: String

    public let isExpired = false

    public let originType = AcceptedOriginType.contactPersonCredentials

    public let username: String
    public let contactPersonID: String
    
    public let projectId: Identifier<Project>
    
    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName, username, contactPersonID, projectId
    }

    private struct InvoiceByLoginOrigin: PaymentRequestOrigin {
        let username: String
        let password: String
        let contactPersonID: String
    }

    public init?(cert gatewayCert: Data?, _ displayName: String, _ username: String, _ password: String, _ contactPersonID: String, _ projectId: Identifier<Project>) {
        let requestOrigin = InvoiceByLoginOrigin(username: username, password: password, contactPersonID: contactPersonID)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial

        self.displayName = displayName

        self.username = username
        self.contactPersonID = contactPersonID
        self.projectId = projectId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encryptedPaymentData = try container.decode(String.self, forKey: .encryptedPaymentData)
        self.serial = try container.decode(String.self, forKey: .serial)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.username = try container.decode(String.self, forKey: .username)
        self.contactPersonID = try container.decode(String.self, forKey: .contactPersonID)
        self.projectId = try container.decode(Identifier<Project>.self, forKey: .projectId)
    }
}
