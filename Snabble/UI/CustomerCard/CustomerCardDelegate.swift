//
//  CustomerCardDelegate.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import UIKit

public protocol CustomerCardDelegate: class {
    /// called to get a customer's customer/loyalty card number. if not nil, this number is passed to the backend as the
    /// `loyaltyCard` property of the shopping cart, and it is also displayed as part of the QR code, if any of
    /// the `encodedCodes` payment methods is used
    func getCustomerCard(_ project: Project) -> String?
}
