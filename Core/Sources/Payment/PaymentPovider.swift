//
//  PaymentPovider.swift
//  Snabble
//
//  Created by Uwe Tilemann on 20.02.25.
//

import Foundation

public protocol PaymentPovider {
    var method: RawPaymentMethod { get }
    var methodDetail: PaymentMethodDetail? { get }
    var selectable: Bool { get }
    var active: Bool { get }
}
