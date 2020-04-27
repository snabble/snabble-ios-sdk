//
//  TerminalCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public final class TerminalCheckoutViewController: BaseCheckoutViewController {
    override public init(_ process: CheckoutProcess, _ rawJson: [String: Any]?, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        super.init(process, rawJson, cart, delegate)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var viewEvent: AnalyticsEvent {
        return .viewTerminalCheckout
    }

    override public func qrCodeContent(_ process: CheckoutProcess, _ id: String) -> String {
        return process.paymentInformation?.qrCodeContent ?? "snabble:checkoutProcess:" + id
    }

    override public func showQrCode(_ process: CheckoutProcess) -> Bool {
        return process.paymentState == .pending
    }
}
