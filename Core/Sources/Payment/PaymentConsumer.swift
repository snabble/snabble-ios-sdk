//
//  PaymentConsumer.swift
//  Snabble
//
//  Created by Uwe Tilemann on 20.02.25.
//

import Foundation

public protocol PaymentConsumer {
    var paymentMethods: [PaymentMethodDescription]? { get }
    var supportedPayments: [RawPaymentMethod]? { get }
}
