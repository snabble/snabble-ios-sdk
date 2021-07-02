//
//  ApplePaySupport.swift
//  Snabble
//
//  Created by Gereon Steffens on 02.07.21.
//

import PassKit

// utility functions to check Apple Pay availability

enum ApplePaySupport {
    // Does the device/OS support Apple Pay? This does not check if any cards have been added to the wallet!
    // Use this to decide whether to show Apple Pay in the popup or not
    static func applePaySupported() -> Bool {
        PKPaymentAuthorizationViewController.canMakePayments()
    }

    // Is there a card in the wallet that allows a payment?
    // Use this to determine if Apple Pay can be selected from the selection or as the default
    static func canMakePayments() -> Bool {
        return applePaySupported() &&
            PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks(), capabilities: .capability3DS)
    }

    static func supportedNetworks() -> [PKPaymentNetwork] {
        let project = SnabbleUI.project
        return project.paymentMethods.compactMap { $0.network }
    }
}

// we check apple pay networks based on the availability of our "regular" credit card methods
fileprivate extension RawPaymentMethod {
    var network: PKPaymentNetwork? {
        switch self {
        case .creditCardVisa: return .visa
        case .creditCardMastercard: return .masterCard
        case .creditCardAmericanExpress: return .amex
        default: return nil
        }
    }
}
