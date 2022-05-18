//
//  CheckoutInfoViolation+Localization.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 18.05.22.
//

import Foundation
import UIKit

extension CheckoutInfo.Violation {
    public var text: String {
        switch type {
        case .unknown:
            return message
        case .couponInvalid:
            return L10n.Snabble.Violations.couponInvalid
        case .couponAlreadyVoided:
            return L10n.Snabble.Violations.couponAlreadyVoided
        case .couponCurrentlyNotValid:
            return L10n.Snabble.Violations.couponCurrentlyNotValid
        }
    }
}
