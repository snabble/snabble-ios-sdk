//
//  EncryptedPaymentData.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public protocol EncryptedPaymentData {
    // encrypted JSON string
    var encryptedPaymentData: String { get }

    // serial # of the certificate used to encrypt
    var serial: String { get }

    // name of this payment method for display
    var displayName: String { get }

    // check if this payment method data is expired
    var isExpired: Bool { get }
    
    var validUntil: String? { get }

    var originType: AcceptedOriginType { get }
}
