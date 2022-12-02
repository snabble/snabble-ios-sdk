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

extension PaymentMethodDetail {
    public static var userPaymentMethodDetails: [PaymentMethodDetail] {
        PaymentMethodDetails.read()
           .filter { $0.rawMethod.isAvailable }
           .filter { $0.projectId != nil ? $0.projectId == SnabbleCI.project.id : true }
    }
    
    public static func paymentDetailFor(rawMethod: RawPaymentMethod?) -> PaymentMethodDetail? {
        guard let rawMethod = rawMethod else {
            return nil
        }
        guard SnabbleCI.project.availablePaymentMethods.contains(rawMethod) else {
            return nil
        }

        guard rawMethod.dataRequired else {
            return nil
        }
        let userMethods = userPaymentMethodDetails
        
        guard let userMethod = userMethods.first(where: { $0.rawMethod == rawMethod }) else {
            return nil
        }
        return userMethod
    }
}
