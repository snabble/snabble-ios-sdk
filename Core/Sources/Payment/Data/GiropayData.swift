//
//  GiropayData.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public struct GiropayData: Codable, EncryptedPaymentData, Equatable {
    // encrypted JSON string
    public let encryptedPaymentData: String
    // serial # of the certificate used to encrypt
    public let serial: String

    // name of this payment method for display in table
    public let displayName: String

    public let isExpired = false
    
    public let validUntil: String? = nil

    public let originType = AcceptedOriginType.giropayCustomerAuthorization

    let deviceId: String
    let deviceName: String
    let deviceFingerprint: String
    let deviceIpAddress: String

    enum CodingKeys: String, CodingKey {
        case encryptedPaymentData, serial, displayName, deviceId, deviceName
        case deviceFingerprint, deviceIpAddress
    }

    private struct GiropayOrigin: PaymentRequestOrigin {
        let clientID: String
        let customerAuthorizationURI: String
    }

    public init?(_ gatewayCert: Data?, _ authorizationURI: String, _ auth: GiropayAuthorization) {
        let requestOrigin = GiropayOrigin(clientID: Snabble.clientId, customerAuthorizationURI: authorizationURI)

        guard
            let encrypter = PaymentDataEncrypter(gatewayCert),
            let (cipherText, serial) = encrypter.encrypt(requestOrigin)
        else {
            return nil
        }

        self.encryptedPaymentData = cipherText
        self.serial = serial

        self.displayName = "giropay"

        self.deviceId = auth.id
        self.deviceName = auth.name
        self.deviceFingerprint = auth.fingerprint
        self.deviceIpAddress = auth.ipAddress
    }

    var additionalData: [String: String] {
        return [
            "deviceID": self.deviceId,
            "deviceName": self.deviceName,
            "deviceFingerprint": self.deviceFingerprint,
            "deviceIPAddress": self.deviceIpAddress
        ]
    }
}
