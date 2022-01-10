//
//  ApplePaySupport.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import PassKit

// utility functions to check Apple Pay availability

public enum ApplePay {
    // Does the device/OS support Apple Pay? This does not check if any cards have been added to the wallet!
    // Use this to decide whether to show Apple Pay in the popup or not
    static func isSupported() -> Bool {
        return false
        PKPaymentAuthorizationViewController.canMakePayments()
    }

    // Is there a card in the wallet that allows a payment?
    // Use this to determine if Apple Pay can be selected from the selection or as the default
    public static func canMakePayments(with projectId: Identifier<Project>) -> Bool {
        return
            SnabbleAPI.project(for: projectId)?.paymentMethods.contains(.applePay) ?? false &&
            isSupported() &&
            PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks(with: projectId), capabilities: .capability3DS)
    }

    static func paymentNetworks(with projectId: Identifier<Project>) -> [PKPaymentNetwork] {
        return SnabbleAPI.project(for: projectId)?.paymentMethods.compactMap { $0.paymentNetwork } ?? []
    }

    static func openPaymentSetup() {
        let library = PKPassLibrary()
        library.openPaymentSetup()
    }
}

// we check apple pay networks based on the availability of our "regular" credit card methods
fileprivate extension RawPaymentMethod {
    var paymentNetwork: PKPaymentNetwork? {
        switch self {
        case .creditCardVisa: return .visa
        case .creditCardMastercard: return .masterCard
        case .creditCardAmericanExpress: return .amex
        default: return nil
        }
    }
}
