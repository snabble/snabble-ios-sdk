//
//  PaymentMethodNavigationDelegate.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

public protocol PaymentMethodNavigationDelegate: AnyObject {
    func addMethod(fromCart: Bool)

    func addData(for method: RawPaymentMethod, in projectId: Identifier<Project>?)

    func showRetailers(for brandId: Identifier<Brand>)

    func showData(for projectId: Identifier<Project>)
    func showData(for method: RawPaymentMethod, in projectId: Identifier<Project>?)

    func editMethod(_ detail: PaymentMethodDetail)

    func goBack()

    func goBackToCart()
}
