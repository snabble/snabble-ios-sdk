//
//  CheckoutInfoViolation+Localization.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 18.05.22.
//

import Foundation
import UIKit
import SnabbleCore
import SnabbleAssetProviding

extension CheckoutInfo.Violation {
    public var text: String {
        switch type {
        case .unknown:
            return message
        case .couponInvalid:
            return Asset.localizedString(forKey: "Snabble.Violations.couponInvalid")
        case .couponAlreadyVoided:
            return Asset.localizedString(forKey: "Snabble.Violations.couponAlreadyVoided")
        case .couponCurrentlyNotValid:
            return Asset.localizedString(forKey: "Snabble.Violations.couponCurrentlyNotValid")
        case .depositReturnVoucherDuplicate:
            return Asset.localizedString(forKey: "Snabble.Violations.DepositReturnVoucher.duplicated")
        }
    }
}

extension Array where Element == CheckoutInfo.Violation {
    var message: String {
        self
            .map { $0.text }
            .joined(separator: "\n")
    }
}
