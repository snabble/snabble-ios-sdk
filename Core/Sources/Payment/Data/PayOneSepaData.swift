//
//  PayOneSepaData.swift
//  
//
//  Created by Uwe Tilemann on 21.11.22.
//

import Foundation

public struct PayoneSepaData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    public let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    public let serial: String

    // name of this payment method for display in table
    public var displayName: String

    public var isExpired: Bool = false
    public let validUntil: String? = nil
    
    public var originType = AcceptedOriginType.payoneSepaData
    
    public let projectId: Identifier<Project>
    public let lastName: String
    
    public var mandateReference: String?
    public var mandateMarkup: String?
    
    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName, projectId, lastName, mandateReference, mandateMarkup
    }

    /// array of supported IBAN countries, return a list if iso country names or `"*"` for all. (see IBAN.countries for all possible country codes)
    public static let countries: [String] = ["DE"]

    private struct DirectDebitRequestOrigin: PaymentRequestOrigin {
        let iban: String
        let lastname: String
        let city: String
        let countryCode: String
    }

    public init?(_ gatewayCert: Data?, iban: String, lastName: String, city: String, countryCode: String, projectId: Identifier<Project>, mandateReference: String? = nil, mandateMarkup: String? = nil) {
        let requestOrigin = DirectDebitRequestOrigin(iban: iban, lastname: lastName, city: city, countryCode: countryCode)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial

        self.displayName = IBAN.displayName(iban)
        self.projectId = projectId
        self.lastName = lastName
        
        self.mandateReference = mandateReference
        self.mandateMarkup = mandateMarkup
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encryptedPaymentData = try container.decode(String.self, forKey: .encryptedPaymentData)
        self.serial = try container.decode(String.self, forKey: .serial)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.projectId = try container.decode(Identifier<Project>.self, forKey: .projectId)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.mandateReference = try container.decodeIfPresent(String.self, forKey: .mandateReference)
        self.mandateMarkup = try container.decodeIfPresent(String.self, forKey: .mandateMarkup)
    }

}
