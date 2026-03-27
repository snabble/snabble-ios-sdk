//
//  Notification+PaymentMethods.swift
//
//
//  Created by Uwe Tilemann on 16.03.26.
//

import Foundation

extension Notification.Name {
    /// Posted when a payment method is successfully added from UIKit ViewControllers
    static let paymentMethodAdded = Notification.Name("snabble.paymentMethodAdded")
}
