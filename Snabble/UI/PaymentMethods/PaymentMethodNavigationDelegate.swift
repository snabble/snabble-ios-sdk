//
//  PaymentMethodListViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

public protocol PaymentMethodNavigationDelegate: class {
    func addMethod()
    func addData(for method: RawPaymentMethod)
    func editMethod(_ method: RawPaymentMethod, _ index: Int)

    func goBack()
    func goBack(_ levels: Int)
}

public extension PaymentMethodNavigationDelegate {
    func goBack(_ levels: Int) {
        for _ in 0 ..< levels {
            self.goBack()
        }
    }
}
