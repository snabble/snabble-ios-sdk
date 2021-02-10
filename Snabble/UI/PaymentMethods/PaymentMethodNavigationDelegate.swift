//
//  PaymentMethodNavigationDelegate.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

public protocol PaymentMethodNavigationDelegate: AnyObject {
    func addMethod(fromCart: Bool)

    func addData(for method: RawPaymentMethod)
    func editMethod(_ method: RawPaymentMethod)

    func goBack()

    func goBackToCart()
}
