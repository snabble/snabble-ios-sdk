//
//  PaymentMethodListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

public protocol PaymentMethodNavigationDelegate: class {
    func addMethod(fromCart: Bool)

    func addData(for method: RawPaymentMethod)
    func editMethod(_ method: RawPaymentMethod, _ index: Int)

    func goBack()

    func goBackToCart()
}
