//
//  PaymentMethod+UI.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import SnabbleCore

/// map payment methods to icons and the UIViewControllers that implement them
extension PaymentMethod {
    public var dataRequired: Bool {
        switch self {
        case .deDirectDebit, .visa, .mastercard, .americanExpress,
             .externalBilling, .paydirektOneKlick, .twint, .postFinanceCard:
            return true
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal, .customerCardPOS, .applePay:
            return false
        }
    }

    public func canStart() -> Bool {
        if !self.dataRequired {
            return true
        } else {
            return self.data != nil
        }
    }

    public var displayName: String? {
        if let dataName = self.data?.displayName {
            return dataName
        }

        return self.rawMethod.displayName
    }
}
