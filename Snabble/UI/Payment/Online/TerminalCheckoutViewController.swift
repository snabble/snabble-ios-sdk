//
//  TerminalCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public final class TerminalCheckoutViewController: BaseCheckoutViewController {
    override public init(_ process: CheckoutProcess, _ cart: ShoppingCart, _ delegate: PaymentDelegate?) {
        super.init(process, cart, delegate)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var viewEvent: AnalyticsEvent {
        return .viewTerminalCheckout
    }

    override public func qrCodeContent(_ process: CheckoutProcess) -> String {
        return process.paymentInformation?.qrCodeContent ?? "snabble:checkoutProcess:\(process.id)"
    }

    override public func showQrCode(_ process: CheckoutProcess) -> Bool {
        return process.paymentState == .pending
    }
}
