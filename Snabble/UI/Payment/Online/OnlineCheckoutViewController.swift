//
//  OnlineCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

public final class OnlineCheckoutViewController: BaseCheckoutViewController {
    override public init(_ process: CheckoutProcess, _ rawJson: [String: Any]?, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        super.init(process, rawJson, cart, delegate)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var viewEvent: AnalyticsEvent {
        return .viewOnlineCheckout
    }

    override public func qrCodeContent(_ process: CheckoutProcess, _ id: String) -> String {
        return process.paymentInformation?.qrCodeContent ?? id
    }

    override public func showQrCode(_ process: CheckoutProcess) -> Bool {
        return process.supervisorApproval == nil
    }
}
